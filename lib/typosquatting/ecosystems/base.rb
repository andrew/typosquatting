# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Base
      attr_reader :name, :purl_type

      def initialize
        @name = self.class.name.split("::").last.downcase
        @purl_type = @name
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?

        !!(name =~ name_pattern)
      end

      def normalise(name)
        name
      end

      def name_pattern
        raise NotImplementedError, "Subclasses must implement #name_pattern"
      end

      def allowed_characters
        raise NotImplementedError, "Subclasses must implement #allowed_characters"
      end

      def allowed_delimiters
        []
      end

      def case_sensitive?
        true
      end

      def supports_namespaces?
        false
      end

      def namespace_controls_members?
        true
      end

      def parse_namespace(name)
        [nil, name]
      end

      def self.get(ecosystem)
        registry[ecosystem.to_s.downcase] || raise(ArgumentError, "Unknown ecosystem: #{ecosystem}")
      end

      def self.all
        registry.values
      end

      def self.register(ecosystem)
        registry[ecosystem.purl_type] = ecosystem
        registry[ecosystem.name] = ecosystem if ecosystem.name != ecosystem.purl_type
      end

      def self.registry
        @registry ||= {}
      end
    end
  end
end
