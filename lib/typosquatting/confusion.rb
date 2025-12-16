# frozen_string_literal: true

module Typosquatting
  class Confusion
    attr_reader :ecosystem, :lookup

    def initialize(ecosystem:)
      @ecosystem = ecosystem.is_a?(String) ? Ecosystems::Base.get(ecosystem) : ecosystem
      @lookup = Lookup.new(ecosystem: @ecosystem)
    end

    def check(package_name)
      result = lookup.check(package_name)
      all_registries = lookup.registries

      registry_status = {}
      all_registries.each do |registry|
        registry_status[registry.name] = result.registries.include?(registry.name)
      end

      ConfusionResult.new(
        name: package_name,
        purl: result.purl,
        registry_status: registry_status,
        exists_anywhere: result.exists?,
        packages: result.packages
      )
    end

    def check_many(package_names)
      package_names.map { |name| check(name) }
    end

    ConfusionResult = Struct.new(:name, :purl, :registry_status, :exists_anywhere, :packages, keyword_init: true) do
      def confusion_risk?
        return false unless exists_anywhere
        return false if registry_status.empty?

        present_count = registry_status.values.count(true)
        absent_count = registry_status.values.count(false)

        present_count > 0 && absent_count > 0
      end

      def present_registries
        registry_status.select { |_, v| v }.keys
      end

      def absent_registries
        registry_status.reject { |_, v| v }.keys
      end

      def registries
        registry_status
      end

      def to_h
        {
          name: name,
          purl: purl,
          exists_anywhere: exists_anywhere,
          confusion_risk: confusion_risk?,
          registries: registry_status,
          present_registries: present_registries,
          absent_registries: absent_registries
        }
      end
    end
  end
end
