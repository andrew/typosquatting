# frozen_string_literal: true

require "sbom"
require "purl"

module Typosquatting
  class SBOMChecker
    attr_reader :sbom

    def initialize(file_path)
      @sbom = Sbom::Parser.new.parse_file(file_path)
    end

    def check
      results = []

      sbom.packages.each do |pkg|
        purl_string = extract_purl(pkg)
        next unless purl_string

        begin
          purl = Purl.parse(purl_string)
        rescue StandardError
          next
        end

        begin
          ecosystem = Ecosystems::Base.get(purl.type)
        rescue ArgumentError
          next
        end

        package_name = purl.namespace ? "#{purl.namespace}/#{purl.name}" : purl.name
        suspicions = find_typosquat_matches(package_name, ecosystem)
        next if suspicions.empty?

        results << SBOMResult.new(
          name: package_name,
          version: purl.version,
          ecosystem: purl.type,
          purl: purl_string,
          suspicions: suspicions
        )
      end

      results
    end

    SBOMResult = Struct.new(:name, :version, :ecosystem, :purl, :suspicions, keyword_init: true) do
      def to_h
        {
          name: name,
          version: version,
          ecosystem: ecosystem,
          purl: purl,
          similar_to: suspicions.map(&:to_h)
        }
      end
    end

    Suspicion = Struct.new(:name, :algorithm, :registries, keyword_init: true) do
      def to_h
        {
          name: name,
          algorithm: algorithm,
          registries: registries
        }
      end
    end

    def extract_purl(package)
      refs = package[:external_references] || []
      purl_ref = refs.find { |r| r[1] == "purl" }
      purl_ref&.[](2)
    end

    def find_typosquat_matches(package_name, ecosystem)
      generator = Generator.new(ecosystem: ecosystem)
      lookup = Lookup.new(ecosystem: ecosystem)

      variants = generator.generate(package_name)
      return [] if variants.empty?

      variant_names = variants.map(&:name)
      results = lookup.bulk_lookup(variant_names)

      results_by_name = results.to_h { |r| [r.name, r] }

      variants.filter_map do |variant|
        result = results_by_name[variant.name]
        next unless result&.exists?

        Suspicion.new(
          name: variant.name,
          algorithm: variant.algorithm,
          registries: result.registries
        )
      end
    end
  end
end
