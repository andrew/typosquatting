# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class DoubleHit < Base
      KEYBOARD_ADJACENT = Replacement::KEYBOARD_ADJACENT

      def generate(package_name)
        variants = []

        (package_name.length - 1).times do |i|
          next unless package_name[i] == package_name[i + 1]

          char = package_name[i].downcase
          adjacent = KEYBOARD_ADJACENT[char] || []

          adjacent.each do |adj_char|
            variant = package_name[0...i] + adj_char + adj_char + package_name[(i + 2)..]
            variants << variant
          end
        end

        variants.uniq
      end
    end
  end
end
