# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class VowelSwap < Base
      VOWELS = %w[a e i o u y].freeze

      def generate(package_name)
        variants = []

        package_name.each_char.with_index do |char, i|
          next unless VOWELS.include?(char.downcase)

          VOWELS.each do |vowel|
            next if vowel == char.downcase

            replacement = char == char.upcase ? vowel.upcase : vowel
            variant = package_name[0...i] + replacement + package_name[(i + 1)..]
            variants << variant
          end
        end

        variants.uniq
      end
    end
  end
end
