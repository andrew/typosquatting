# frozen_string_literal: true

require "optparse"
require "json"

module Typosquatting
  class CLI
    def self.run(args = ARGV)
      new.run(args)
    end

    def run(args)
      command = args.shift
      case command
      when "generate"
        generate(args)
      when "check"
        check(args)
      when "confusion"
        confusion(args)
      when "sbom"
        sbom(args)
      when "ecosystems"
        ecosystems
      when "algorithms"
        algorithms
      when "version", "-v", "--version"
        version
      when "help", "-h", "--help", nil
        help
      else
        $stderr.puts "Unknown command: #{command}"
        help
        exit 1
      end
    end

    def generate(args)
      options = { format: "text", verbose: false, length_filtering: true }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: typosquatting generate PACKAGE -e ECOSYSTEM [options]"
        opts.on("-e", "--ecosystem ECOSYSTEM", "Package ecosystem (required)") { |v| options[:ecosystem] = v }
        opts.on("-f", "--format FORMAT", "Output format (text, json, csv)") { |v| options[:format] = v }
        opts.on("-v", "--verbose", "Show algorithm for each variant") { options[:verbose] = true }
        opts.on("-a", "--algorithms LIST", "Comma-separated list of algorithms to use") { |v| options[:algorithms] = v }
        opts.on("--no-length-filter", "Disable length-based algorithm filtering for short names") { options[:length_filtering] = false }
      end
      parser.parse!(args)

      package = args.shift
      unless package && options[:ecosystem]
        $stderr.puts "Error: Package name and ecosystem required"
        $stderr.puts parser
        exit 1
      end

      ecosystem = Ecosystems::Base.get(options[:ecosystem])
      algorithms = select_algorithms(options[:algorithms])
      generator = Generator.new(ecosystem: ecosystem, algorithms: algorithms, length_filtering: options[:length_filtering])
      variants = generator.generate(package)

      output_variants(variants, options)
    end

    def check(args)
      options = { format: "text", verbose: false, existing_only: false, dry_run: false, length_filtering: true }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: typosquatting check PACKAGE -e ECOSYSTEM [options]"
        opts.on("-e", "--ecosystem ECOSYSTEM", "Package ecosystem (required)") { |v| options[:ecosystem] = v }
        opts.on("-f", "--format FORMAT", "Output format (text, json, csv)") { |v| options[:format] = v }
        opts.on("-v", "--verbose", "Show algorithm and registry details") { options[:verbose] = true }
        opts.on("-a", "--algorithms LIST", "Comma-separated list of algorithms to use") { |v| options[:algorithms] = v }
        opts.on("--existing-only", "Only show packages that exist") { options[:existing_only] = true }
        opts.on("--dry-run", "Show variants without making API calls") { options[:dry_run] = true }
        opts.on("--no-length-filter", "Disable length-based algorithm filtering for short names") { options[:length_filtering] = false }
      end
      parser.parse!(args)

      package = args.shift
      unless package && options[:ecosystem]
        $stderr.puts "Error: Package name and ecosystem required"
        $stderr.puts parser
        exit 1
      end

      ecosystem = Ecosystems::Base.get(options[:ecosystem])
      algorithms = select_algorithms(options[:algorithms])
      generator = Generator.new(ecosystem: ecosystem, algorithms: algorithms, length_filtering: options[:length_filtering])
      variants = generator.generate(package)

      if options[:dry_run]
        puts "Would check #{variants.length} variants:"
        variants.each { |v| puts "  #{v.name}" }
        return
      end

      lookup = Lookup.new(ecosystem: ecosystem)
      results = check_variants(variants, lookup)
      results = results.select { |r| r[:result].exists? } if options[:existing_only]

      output_check_results(results, options)
    end

    def confusion(args)
      options = { format: "text" }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: typosquatting confusion PACKAGE -e ECOSYSTEM [options]"
        opts.on("-e", "--ecosystem ECOSYSTEM", "Package ecosystem (required)") { |v| options[:ecosystem] = v }
        opts.on("-f", "--format FORMAT", "Output format (text, json)") { |v| options[:format] = v }
        opts.on("--file FILE", "Read package names from file") { |v| options[:file] = v }
      end
      parser.parse!(args)

      unless options[:ecosystem]
        $stderr.puts "Error: Ecosystem required"
        $stderr.puts parser
        exit 1
      end

      packages = if options[:file]
                   File.readlines(options[:file]).map(&:strip).reject(&:empty?)
                 else
                   package = args.shift
                   unless package
                     $stderr.puts "Error: Package name or --file required"
                     exit 1
                   end
                   [package]
                 end

      confusion_checker = Confusion.new(ecosystem: options[:ecosystem])
      results = packages.map do |pkg|
        $stderr.puts "Checking #{pkg}..." if packages.length > 1
        confusion_checker.check(pkg)
      end

      output_confusion_results(results, options)
    end

    def sbom(args)
      options = { format: "text", dry_run: false }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: typosquatting sbom FILE [options]"
        opts.on("-f", "--format FORMAT", "Output format (text, json)") { |v| options[:format] = v }
        opts.on("--dry-run", "Show packages without making API calls") { options[:dry_run] = true }
      end
      parser.parse!(args)

      file = args.shift
      unless file
        $stderr.puts "Error: SBOM file required"
        $stderr.puts parser
        exit 1
      end

      unless File.exist?(file)
        $stderr.puts "Error: File not found: #{file}"
        exit 1
      end

      checker = SBOMChecker.new(file)

      if options[:dry_run]
        puts "Packages in SBOM:"
        checker.sbom.packages.each do |pkg|
          purl = checker.extract_purl(pkg)
          puts "  #{pkg[:name]} (#{purl || "no purl"})"
        end
        puts ""
        puts "#{checker.sbom.packages.length} packages found"
        return
      end

      results = checker.check

      output_sbom_results(results, options)
    end

    def ecosystems
      puts "Supported ecosystems:"
      puts ""
      puts "  pypi           - Python Package Index"
      puts "  npm            - Node Package Manager"
      puts "  gem            - RubyGems"
      puts "  cargo          - Rust packages"
      puts "  golang         - Go modules"
      puts "  maven          - Java/JVM packages"
      puts "  nuget          - .NET packages"
      puts "  composer       - PHP packages"
      puts "  hex            - Erlang/Elixir packages"
      puts "  pub            - Dart packages"
      puts "  github_actions - GitHub Actions"
    end

    def algorithms
      puts "Typosquatting algorithms:"
      puts ""
      Algorithms::Base.all.each do |algo|
        puts "  #{algo.name}"
      end
    end

    def version
      puts "typosquatting #{VERSION}"
    end

    def help
      puts "typosquatting - Detect potential typosquatting packages"
      puts ""
      puts "Usage: typosquatting COMMAND [options]"
      puts ""
      puts "Commands:"
      puts "  generate PACKAGE -e ECOSYSTEM    Generate typosquat variants"
      puts "  check PACKAGE -e ECOSYSTEM       Check which variants exist"
      puts "  confusion PACKAGE -e ECOSYSTEM   Check for dependency confusion"
      puts "  sbom FILE                        Check SBOM for potential typosquats"
      puts "  ecosystems                       List supported ecosystems"
      puts "  algorithms                       List typosquatting algorithms"
      puts "  version                          Show version"
      puts "  help                             Show this help"
      puts ""
      puts "Examples:"
      puts "  typosquatting generate requests -e pypi"
      puts "  typosquatting check requests -e pypi --existing-only"
      puts "  typosquatting confusion my-package -e maven"
      puts "  typosquatting sbom bom.json"
    end

    def output_variants(variants, options)
      case options[:format]
      when "json"
        data = variants.map { |v| options[:verbose] ? v.to_h : v.name }
        puts JSON.pretty_generate(data)
      when "csv"
        if options[:verbose]
          puts "name,algorithm"
          variants.each { |v| puts "#{v.name},#{v.algorithm}" }
        else
          variants.each { |v| puts v.name }
        end
      else
        if options[:verbose]
          variants.each { |v| puts "#{v.name} (#{v.algorithm})" }
        else
          variants.each { |v| puts v.name }
        end
      end

      $stderr.puts ""
      $stderr.puts "Generated #{variants.length} variants"
    end

    def output_check_results(results, options)
      case options[:format]
      when "json"
        data = results.map do |r|
          {
            name: r[:variant].name,
            algorithm: r[:variant].algorithm,
            exists: r[:result].exists?,
            registries: r[:result].registries
          }
        end
        puts JSON.pretty_generate(data)
      when "csv"
        puts "name,algorithm,exists,registries"
        results.each do |r|
          puts "#{r[:variant].name},#{r[:variant].algorithm},#{r[:result].exists?},\"#{r[:result].registries.join("; ")}\""
        end
      else
        results.each do |r|
          status = r[:result].exists? ? "EXISTS" : "available"
          if options[:verbose]
            puts "#{r[:variant].name} (#{r[:variant].algorithm}) - #{status}"
            puts "  registries: #{r[:result].registries.join(", ")}" if r[:result].exists?
          else
            puts "#{r[:variant].name} - #{status}"
          end
        end

        puts ""
        existing = results.count { |r| r[:result].exists? }
        puts "Checked #{results.length} variants, #{existing} exist"
      end
    end

    def output_confusion_results(results, options)
      case options[:format]
      when "json"
        data = results.map(&:to_h)
        puts JSON.pretty_generate(data)
      else
        results.each do |result|
          puts ""
          puts "Package: #{result.name}"
          puts "PURL: #{result.purl}"

          if result.registry_status.empty?
            puts "  No registries found for this ecosystem"
          else
            result.registry_status.each do |registry, exists|
              status = exists ? "EXISTS" : "available"
              puts "  #{registry}: #{status}"
            end
          end

          if result.confusion_risk?
            puts ""
            puts "WARNING: Dependency confusion risk detected!"
            puts "Package exists on: #{result.present_registries.join(", ")}"
            puts "Package missing from: #{result.absent_registries.join(", ")}"
          elsif result.exists_anywhere
            puts ""
            puts "Package exists on all registries"
          else
            puts ""
            puts "Package does not exist on any registry"
          end
        end
      end
    end

    def check_variants(variants, lookup)
      $stderr.puts "Checking #{variants.length} variants..." if $stderr.tty?

      names = variants.map(&:name)
      api_results = lookup.check_many(names, concurrency: 10)

      variants.zip(api_results).map do |variant, result|
        { variant: variant, result: result }
      end
    end

    def select_algorithms(algorithm_list)
      return nil unless algorithm_list

      names = algorithm_list.split(",").map(&:strip)
      all_algorithms = Algorithms::Base.all
      selected = []

      names.each do |name|
        algo = all_algorithms.find { |a| a.name == name }
        if algo
          selected << algo
        else
          $stderr.puts "Warning: Unknown algorithm '#{name}', skipping"
        end
      end

      selected.empty? ? nil : selected
    end

    def output_sbom_results(results, options)
      case options[:format]
      when "json"
        data = results.map(&:to_h)
        puts JSON.pretty_generate(data)
      else
        if results.empty?
          puts "No potential typosquats found in SBOM"
          return
        end

        puts "Potential typosquats found:"
        puts ""

        results.each do |result|
          puts "#{result.name} (#{result.ecosystem})"
          puts "  Version: #{result.version}" if result.version
          puts "  PURL: #{result.purl}"
          puts "  Similar to existing packages:"
          result.suspicions.each do |s|
            puts "    - #{s.name} (#{s.algorithm})"
            puts "      registries: #{s.registries.join(", ")}" unless s.registries.empty?
          end
          puts ""
        end

        puts "Found #{results.length} suspicious package(s)"
      end
    end
  end
end
