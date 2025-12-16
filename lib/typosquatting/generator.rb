# frozen_string_literal: true

module Typosquatting
  class Generator
    attr_reader :ecosystem, :algorithms

    def initialize(ecosystem:, algorithms: nil)
      @ecosystem = ecosystem.is_a?(String) ? Ecosystems::Base.get(ecosystem) : ecosystem
      @algorithms = algorithms || Algorithms::Base.all
    end

    def generate(package_name)
      results = []

      algorithms.each do |algorithm|
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

      dedupe_by_normalised_name(results)
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
