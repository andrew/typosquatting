# frozen_string_literal: true

module Typosquatting
  class Generator
    SHORT_NAME_THRESHOLD = 5

    HIGH_CONFIDENCE_ALGORITHMS = %w[
      homoglyph
      repetition
      replacement
      transposition
    ].freeze

    attr_reader :ecosystem, :algorithms, :length_filtering

    def initialize(ecosystem:, algorithms: nil, length_filtering: true)
      @ecosystem = ecosystem.is_a?(String) ? Ecosystems::Base.get(ecosystem) : ecosystem
      @algorithms = algorithms || Algorithms::Base.all
      @length_filtering = length_filtering
    end

    def generate(package_name)
      results = []

      if ecosystem.supports_namespaces?
        results.concat(generate_namespace_aware(package_name))
      else
        results.concat(generate_simple(package_name))
      end

      dedupe_by_normalised_name(results)
    end

    def algorithms_for_length(name_length)
      return algorithms unless length_filtering
      return algorithms if name_length >= SHORT_NAME_THRESHOLD

      algorithms.select { |a| HIGH_CONFIDENCE_ALGORITHMS.include?(a.name) }
    end

    def generate_simple(package_name)
      results = []
      active_algorithms = algorithms_for_length(package_name.length)

      active_algorithms.each do |algorithm|
        variants = algorithm.generate(package_name)
        variants.each do |variant|
          next if variant == package_name
          next unless ecosystem.valid_name?(variant)
          next if same_after_normalisation?(package_name, variant)

          results << Variant.new(
            name: variant,
            algorithm: algorithm.name,
            original: package_name
          )
        end
      end

      results
    end

    def generate_namespace_aware(package_name)
      namespace, name = ecosystem.parse_namespace(package_name)
      results = []

      return generate_simple(package_name) if namespace.nil?

      namespace_algorithms = algorithms_for_length(namespace.length)
      name_algorithms = algorithms_for_length(name.length)

      namespace_algorithms.each do |algorithm|
        namespace_variants = algorithm.generate(namespace)
        namespace_variants.each do |ns_variant|
          full_name = rebuild_namespaced_name(ns_variant, name)
          next if full_name == package_name
          next unless ecosystem.valid_name?(full_name)
          next if same_after_normalisation?(package_name, full_name)

          results << Variant.new(
            name: full_name,
            algorithm: algorithm.name,
            original: package_name
          )
        end
      end

      unless ecosystem.namespace_controls_members?
        name_algorithms.each do |algorithm|
          name_variants = algorithm.generate(name)
          name_variants.each do |name_variant|
            full_name = rebuild_namespaced_name(namespace, name_variant)
            next if full_name == package_name
            next unless ecosystem.valid_name?(full_name)
            next if same_after_normalisation?(package_name, full_name)

            results << Variant.new(
              name: full_name,
              algorithm: algorithm.name,
              original: package_name
            )
          end
        end
      end

      results
    end

    def rebuild_namespaced_name(namespace, name)
      if ecosystem.respond_to?(:format_name)
        ecosystem.format_name(namespace, name)
      else
        "#{namespace}/#{name}"
      end
    end

    Variant = Struct.new(:name, :algorithm, :original, keyword_init: true) do
      def to_h
        { name: name, algorithm: algorithm, original: original }
      end

      def to_s
        name
      end
    end

    def same_after_normalisation?(original, variant)
      ecosystem.normalise(original) == ecosystem.normalise(variant)
    end

    def dedupe_by_normalised_name(variants)
      seen = {}
      variants.each_with_object([]) do |variant, result|
        normalised = ecosystem.normalise(variant.name)
        unless seen[normalised]
          seen[normalised] = true
          result << variant
        end
      end
    end
  end
end
