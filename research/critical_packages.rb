#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "typosquatting"
require "csv"

class CriticalPackageScanner
  SHORT_NAME_THRESHOLD = 5
  POPULAR_RATIO_THRESHOLD = 1.0 # Skip squats with >= 1% of critical package downloads

  REGISTRY_MAP = {
    "rubygems.org" => "rubygems",
    "npmjs.org" => "npm",
    "pypi.org" => "pypi",
    "crates.io" => "cargo",
    "packagist.org" => "composer",
    "hex.pm" => "hex",
    "pub.dev" => "pub",
    "proxy.golang.org" => "golang",
    "repo1.maven.org" => "maven",
    "nuget.org" => "nuget"
  }.freeze

  # High confidence algorithms that indicate likely intentional typosquatting
  HIGH_CONFIDENCE_ALGORITHMS = %w[
    homoglyph
    repetition
    replacement
    transposition
    omission
  ].freeze

  attr_reader :registry, :results, :errors, :high_confidence_only, :limit

  def initialize(registry:, high_confidence_only: true, limit: nil)
    @registry = registry
    @high_confidence_only = high_confidence_only
    @limit = limit
    @results = []
    @errors = []
    @prefix_cache = {}
  end

  def run
    packages = fetch_critical_packages
    puts "Found #{packages.length} critical packages for #{registry}"
    puts

    packages.each_with_index do |package, index|
      scan_package(package, index + 1, packages.length)
    end

    write_csv
    print_summary
  end

  def fetch_critical_packages
    packages = lookup.list_all_names(registry: registry, critical: true, per_page: 1000)
    limit ? packages.first(limit) : packages
  end

  def scan_package(package_name, current, total)
    print "\r[#{current}/#{total}] Scanning #{package_name.ljust(40)}"

    # Skip short names - too many false positives
    return if package_name.length < SHORT_NAME_THRESHOLD

    # Generate typosquatting variants using our algorithms
    variants = generator.generate(package_name)
    return if variants.empty?

    # Fetch details for the critical package first (needed for download/date comparison)
    critical_details = fetch_package_details(package_name)
    @current_critical_downloads = critical_details&.dig("downloads") || 0
    @current_critical_created = critical_details&.dig("first_release_published_at")

    # Check which variants exist on the registry
    existing = check_variants_exist(package_name, variants)
    return if existing.empty?

    results << {
      package: package_name,
      critical_details: critical_details,
      matches: existing
    }
  rescue Typosquatting::APIError => e
    errors << { package: package_name, error: e.message }
  rescue StandardError => e
    errors << { package: package_name, error: e.message }
  end

  def check_variants_exist(package_name, variants)
    # Filter to high-confidence algorithms if requested
    if high_confidence_only
      variants = variants.select { |v| HIGH_CONFIDENCE_ALGORITHMS.include?(v.algorithm) }
    end

    # Group variants by prefix for efficient lookup
    variants_by_prefix = variants.group_by { |v| v.name[0, 3] }

    existing = []
    variants_by_prefix.each do |prefix, prefix_variants|
      @prefix_cache[prefix] ||= lookup.list_names(registry: registry, prefix: prefix)
      existing_set = @prefix_cache[prefix].map(&:downcase).to_set

      prefix_variants.each do |variant|
        if existing_set.include?(variant.name.downcase) && variant.name.downcase != package_name.downcase
          # Fetch package details
          details = fetch_package_details(variant.name)
          squat_downloads = details&.dig("downloads") || 0
          squat_created = details&.dig("first_release_published_at")

          # Skip if squat has more downloads than critical package - not a squat
          next if squat_downloads > @current_critical_downloads

          # Skip if squat is too popular (likely legitimate)
          if @current_critical_downloads > 0
            ratio = squat_downloads.to_f / @current_critical_downloads * 100
            next if ratio >= POPULAR_RATIO_THRESHOLD
          end

          # Skip if squat predates the critical package (can't be a typosquat)
          if squat_created && @current_critical_created
            next if squat_created < @current_critical_created
          end

          existing << {
            variant: variant,
            description: details&.dig("description"),
            repository_url: details&.dig("repository_url"),
            downloads: squat_downloads,
            first_release: squat_created,
            status: details&.dig("status")
          }
        end
      end
    end

    existing
  end

  def fetch_package_details(package_name)
    result = lookup.check(package_name)
    result.packages.first
  rescue StandardError
    nil
  end

  def generator
    @generator ||= Typosquatting::Generator.new(ecosystem: ecosystem_for_registry)
  end

  def lookup
    @lookup ||= Typosquatting::Lookup.new(ecosystem: ecosystem_for_registry)
  end

  def ecosystem_for_registry
    REGISTRY_MAP[registry] || "rubygems"
  end

  def output_filename
    timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
    "#{registry.gsub(".", "_")}_#{timestamp}.csv"
  end

  def write_csv
    return if results.empty?

    filename = output_filename
    filepath = File.join(__dir__, filename)

    CSV.open(filepath, "w") do |csv|
      csv << [
        "critical_package", "critical_downloads", "critical_created", "critical_repo",
        "potential_typosquat", "algorithm", "squat_downloads", "download_ratio", "squat_created", "squat_status", "squat_repo", "squat_description"
      ]

      results.each do |result|
        critical = result[:critical_details]
        critical_downloads = critical&.dig("downloads") || 0
        result[:matches].each do |match|
          squat_downloads = match[:downloads] || 0
          ratio = critical_downloads > 0 ? (squat_downloads.to_f / critical_downloads * 100).round(4) : 0

          csv << [
            result[:package],
            critical_downloads,
            critical&.dig("first_release_published_at")&.split("T")&.first,
            critical&.dig("repository_url"),
            match[:variant].name,
            match[:variant].algorithm,
            squat_downloads,
            "#{ratio}%",
            match[:first_release]&.split("T")&.first,
            match[:status],
            match[:repository_url],
            match[:description]&.gsub(/\s+/, " ")&.strip
          ]
        end
      end
    end

    puts "\n\nResults written to #{filepath}"
  end

  def print_summary
    puts "\n"
    puts "=" * 60
    puts "Results for #{registry}"
    puts "=" * 60
    puts

    if results.empty?
      puts "No potential typosquats found."
    else
      puts "Found #{results.length} critical packages with potential typosquats"
      puts "Total potential typosquats: #{results.sum { |r| r[:matches].length }}"

      # Algorithm breakdown
      algo_counts = Hash.new(0)
      results.each do |result|
        result[:matches].each { |m| algo_counts[m[:variant].algorithm] += 1 }
      end

      puts "\nBy algorithm:"
      algo_counts.sort_by { |_, count| -count }.each do |algo, count|
        puts "  #{algo}: #{count}"
      end

      # Flag suspicious packages (no repo, low downloads)
      suspicious = []
      results.each do |result|
        result[:matches].each do |match|
          if match[:repository_url].nil? || match[:repository_url].to_s.empty?
            suspicious << "#{match[:variant].name} (no repo, #{match[:downloads] || 0} downloads)"
          end
        end
      end

      if suspicious.any?
        puts "\nSuspicious (no repository):"
        suspicious.first(10).each { |s| puts "  #{s}" }
        puts "  ... and #{suspicious.length - 10} more" if suspicious.length > 10
      end

      # Flag removed/yanked packages (confirmed typosquats)
      removed = []
      results.each do |result|
        result[:matches].each do |match|
          if match[:status] == "removed"
            removed << "#{match[:variant].name} (targeting #{result[:package]})"
          end
        end
      end

      if removed.any?
        puts "\nConfirmed (already yanked):"
        removed.first(10).each { |s| puts "  #{s}" }
        puts "  ... and #{removed.length - 10} more" if removed.length > 10
      end
    end

    return if errors.empty?

    puts "\n" + "=" * 60
    puts "Errors (#{errors.length}):"
    puts "=" * 60
    errors.each do |error|
      puts "  #{error[:package]}: #{error[:error]}"
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  registry = ARGV[0] || "rubygems.org"
  high_confidence_only = !ARGV.include?("--all")
  limit = ARGV.find { |a| a.start_with?("--limit=") }&.split("=")&.last&.to_i

  scanner = CriticalPackageScanner.new(registry: registry, high_confidence_only: high_confidence_only, limit: limit)
  scanner.run
end
