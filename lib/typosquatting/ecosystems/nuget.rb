# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Nuget < Base
      def initialize
        super
        @purl_type = "nuget"
      end

      def name_pattern
        /\A[a-zA-Z0-9][a-zA-Z0-9._-]*\z/
      end

      def allowed_characters
        /[a-zA-Z0-9._-]/
      end

      def allowed_delimiters
        %w[- _ .]
      end

      def case_sensitive?
        false
      end

      def normalise(name)
        name.downcase
      end

      def valid_name?(name)
        return false if name.nil? || name.empty?
        return false if name.length > 100

        !!(name =~ name_pattern)
      end
    end

    Base.register(Nuget.new)
  end
end
