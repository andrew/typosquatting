# frozen_string_literal: true

module Typosquatting
  module Ecosystems
    class Pypi < Base
      def initialize
        super
        @purl_type = "pypi"
      end

      def name_pattern
        /\A[a-zA-Z0-9]([a-zA-Z0-9._-]*[a-zA-Z0-9])?\z/
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
        name.downcase.gsub(/[-_.]+/, "-")
      end

      def equivalent?(name1, name2)
        normalise(name1) == normalise(name2)
      end
    end

    Base.register(Pypi.new)
  end
end
