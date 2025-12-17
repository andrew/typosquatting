# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Golang < Base
      def initialize
        super
        @name = "golang"
        @purl_type = "golang"
      end

      def name_pattern
        /\A[a-zA-Z0-9][a-zA-Z0-9._\/-]*\z/
      end

      def allowed_characters
        /[a-zA-Z0-9._\/-]/
      end

      def allowed_delimiters
        %w[- _ . /]
      end

      def case_sensitive?
        true
      end

      def supports_namespaces?
        true
      end

      def normalise(name)
        name.sub(/\/v\d+$/, "")
      end

      def parse_namespace(name)
        parts = name.split("/")
        if parts.length > 1
          [parts[0..-2].join("/"), parts.last]
        else
          [nil, name]
        end
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?
        return false if name.start_with?("/") || name.end_with?("/")
        return false if name.include?("//")

        !!(name =~ name_pattern)
      end

      def format_name(namespace, name)
        "#{namespace}/#{name}"
      end
    end

    Base.register(Golang.new)
  end
end
