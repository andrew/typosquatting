# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Combosquatting < Base
      SUFFIXES = %w[
        js .js -js
        py -py -python python
        -node node- -npm npm-
        -cli -api -core -utils -util -lib -pkg
        -lite -dev -test -beta -alpha
        -compat -legacy -next -new -v2
        -simd -fast -async
        s -s
      ].freeze

      PREFIXES = %w[
        py- python-
        node- npm-
        go-
        js-
        my- the- a-
      ].freeze

      def generate(package_name)
        variants = []

        SUFFIXES.each do |suffix|
          variants << "#{package_name}#{suffix}"
        end

        PREFIXES.each do |prefix|
          variants << "#{prefix}#{package_name}"
        end

        variants.uniq
      end
    end
  end
end
