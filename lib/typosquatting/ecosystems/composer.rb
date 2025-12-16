# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Composer < Base
      def initialize
        super
        @purl_type = "composer"
      end

      def name_pattern
        /\A[a-z0-9]([a-z0-9_.-]*[a-z0-9])?\/[a-z0-9]([a-z0-9_.-]*[a-z0-9])?\z/
      end

      def allowed_characters
        /[a-z0-9_.\/-]/
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
        parts = name.split("/", 2)
        if parts.length == 2
          [parts[0], parts[1]]
        else
          [nil, name]
        end
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?

        vendor, package = parse_namespace(name)
        return false if vendor.nil? || package.nil?
        return false if vendor.empty? || package.empty?

        vendor_valid = vendor =~ /\A[a-z0-9]([a-z0-9_.-]*[a-z0-9])?\z/i
        package_valid = package =~ /\A[a-z0-9]([a-z0-9_.-]*[a-z0-9])?\z/i

        vendor_valid && package_valid
      end

      def format_name(vendor, package)
        "#{vendor}/#{package}"
      end
    end

    Base.register(Composer.new)
  end
end
