# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Npm < Base
      def initialize
        super
        @purl_type = "npm"
      end

      def name_pattern
        /\A(@[a-z0-9~-][a-z0-9._~-]*\/)?[a-z0-9~-][a-z0-9._~-]*\z/
      end

      def allowed_characters
        /[a-z0-9._~-]/
      end

      def allowed_delimiters
        %w[- _ .]
      end

      def case_sensitive?
        false
      end

      def supports_namespaces?
        true
      end

      def normalise(name)
        name.downcase
      end

      def parse_namespace(name)
        if name.start_with?("@")
          parts = name.split("/", 2)
          [parts[0], parts[1]]
        else
          [nil, name]
        end
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?
        return false if name.length > 214

        namespace, pkg_name = parse_namespace(name)

        if namespace
          return false unless namespace =~ /\A@[a-z0-9~-][a-z0-9._~-]*\z/
          return false if pkg_name.nil? || pkg_name.empty?
        end

        pkg_name = name unless namespace
        return false unless pkg_name =~ /\A[a-z0-9~-][a-z0-9._~-]*\z/
        return false if pkg_name.start_with?(".")
        return false if pkg_name.start_with?("_")

        true
      end
    end

    Base.register(Npm.new)
  end
end
