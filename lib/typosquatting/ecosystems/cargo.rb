# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Cargo < Base
      def initialize
        super
        @purl_type = "cargo"
      end

      def name_pattern
        /\A[a-zA-Z][a-zA-Z0-9_-]*\z/
      end

      def allowed_characters
        /[a-zA-Z0-9_-]/
      end

      def allowed_delimiters
        %w[- _]
      end

      def case_sensitive?
        false
      end

      def normalise(name)
        name.downcase.tr("_", "-")
      end

      def equivalent?(name1, name2)
        normalise(name1) == normalise(name2)
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?
        return false if name.length > 64

        !!(name =~ name_pattern)
      end
    end

    Base.register(Cargo.new)
  end
end
