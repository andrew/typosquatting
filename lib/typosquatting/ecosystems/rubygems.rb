# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Rubygems < Base
      def initialize
        super
        @name = "rubygems"
        @purl_type = "gem"
      end

      def name_pattern
        /\A[a-zA-Z0-9][a-zA-Z0-9_-]*\z/
      end

      def allowed_characters
        /[a-zA-Z0-9_-]/
      end

      def allowed_delimiters
        %w[- _]
      end

      def case_sensitive?
        true
      end

      def normalise(name)
        name
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?
        return false if name.include?(".")

        !!(name =~ name_pattern)
      end
    end

    Base.register(Rubygems.new)
  end
end
