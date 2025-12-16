# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Hex < Base
      def initialize
        super
        @purl_type = "hex"
      end

      def name_pattern
        /\A[a-z][a-z0-9_]*\z/
      end

      def allowed_characters
        /[a-z0-9_]/
      end

      def allowed_delimiters
        %w[_]
      end

      def case_sensitive?
        false
      end

      def normalise(name)
        name.downcase
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?
        return false if name.include?("-")
        return false if name.include?(".")

        !!(name =~ name_pattern)
      end
    end

    Base.register(Hex.new)
  end
end
