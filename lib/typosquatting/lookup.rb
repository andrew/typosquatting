# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "purl"
require "set"

module Typosquatting
  class Lookup
    API_BASE = "https://packages.ecosyste.ms/api/v1"
    USER_AGENT = "typosquatting-ruby/#{VERSION} (https://github.com/andrew/typosquatting)"

    attr_reader :ecosystem

    def initialize(ecosystem:)
      @ecosystem = ecosystem.is_a?(String) ? Ecosystems::Base.get(ecosystem) : ecosystem
    end

    def check(package_name)
      purl = build_purl(package_name)
      response = fetch("/packages/lookup?purl=#{URI.encode_www_form_component(purl.to_s)}")

      Result.new(
        name: package_name,
        purl: purl.to_s,
        packages: response || [],
        ecosystem: ecosystem.purl_type
      )
    end

    def check_many(package_names, concurrency: 10)
      results = []
      mutex = Mutex.new
      queue = package_names.dup

      threads = concurrency.times.map do
        Thread.new do
          while (name = mutex.synchronize { queue.shift })
            result = check(name)
            mutex.synchronize { results << [name, result] }
          end
        end
      end

      threads.each(&:join)
      package_names.map { |name| results.find { |n, _| n == name }&.last }
    end

    def registries
      response = fetch("/registries?ecosystem=#{URI.encode_www_form_component(ecosystem.purl_type)}")
      response&.map { |r| Registry.new(r) } || []
    end

    def list_names(registry:, prefix: nil, postfix: nil)
      params = []
      params << "prefix=#{URI.encode_www_form_component(prefix)}" if prefix
      params << "postfix=#{URI.encode_www_form_component(postfix)}" if postfix
      query = params.empty? ? "" : "?#{params.join("&")}"

      fetch("/registries/#{URI.encode_www_form_component(registry)}/package_names#{query}") || []
    end

    def discover(package_name, max_distance: 2)
      registry = registries.first
      return [] unless registry

      prefix = package_name[0, 3]
      candidates = list_names(registry: registry.name, prefix: prefix)

      candidates.filter_map do |candidate|
        next if candidate == package_name

        distance = levenshtein(package_name.downcase, candidate.downcase)
        next if distance > max_distance || distance == 0

        DiscoveryResult.new(
          name: candidate,
          target: package_name,
          distance: distance
        )
      end.sort_by(&:distance)
    end

    def check_with_variants(package_name, variants)
      registry = registries.first
      return [] unless registry

      prefix = package_name[0, 3]
      existing = list_names(registry: registry.name, prefix: prefix)
      existing_set = existing.map(&:downcase).to_set

      variant_names = variants.map { |v| v.is_a?(String) ? v : v.name }

      variant_names.filter_map do |variant|
        exists = existing_set.include?(variant.downcase)
        VariantCheckResult.new(
          name: variant,
          exists: exists
        )
      end
    end

    def levenshtein(s1, s2)
      m, n = s1.length, s2.length
      return n if m == 0
      return m if n == 0

      d = Array.new(m + 1) { |i| i }
      x = nil

      (1..n).each do |j|
        d[0] = j
        x = j - 1

        (1..m).each do |i|
          cost = s1[i - 1] == s2[j - 1] ? 0 : 1
          x, d[i] = d[i], [d[i] + 1, d[i - 1] + 1, x + cost].min
        end
      end

      d[m]
    end

    DiscoveryResult = Struct.new(:name, :target, :distance, keyword_init: true) do
      def to_h
        { name: name, target: target, distance: distance }
      end
    end

    VariantCheckResult = Struct.new(:name, :exists, keyword_init: true) do
      def exists?
        exists
      end

      def to_h
        { name: name, exists: exists }
      end
    end

    Result = Struct.new(:name, :purl, :packages, :ecosystem, keyword_init: true) do
      def exists?
        !packages.empty?
      end

      def registries
        packages.map { |p| p.dig("registry", "name") }.compact.uniq
      end

      def to_h
        {
          name: name,
          purl: purl,
          exists: exists?,
          registries: registries,
          packages: packages
        }
      end
    end

    Registry = Struct.new(:data) do
      def name
        data["name"]
      end

      def url
        data["url"]
      end

      def ecosystem
        data["ecosystem"]
      end

      def packages_count
        data["packages_count"]
      end

      def to_h
        data
      end
    end

    def build_purl(package_name)
      if ecosystem.supports_namespaces?
        namespace, name = ecosystem.parse_namespace(package_name)
        Purl::PackageURL.new(
          type: ecosystem.purl_type,
          namespace: namespace,
          name: name
        )
      else
        Purl::PackageURL.new(
          type: ecosystem.purl_type,
          name: package_name
        )
      end
    end

    def fetch(path)
      uri = URI("#{API_BASE}#{path}")
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = "application/json"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      case response
      when Net::HTTPSuccess
        JSON.parse(response.body)
      when Net::HTTPNotFound
        []
      else
        raise APIError, "API request failed: #{response.code} #{response.message}"
      end
    rescue StandardError => e
      raise APIError, "API request failed: #{e.message}" unless e.is_a?(APIError)

      raise
    end
  end

  class APIError < StandardError; end
end
