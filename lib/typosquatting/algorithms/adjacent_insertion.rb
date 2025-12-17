# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class AdjacentInsertion < Base
      KEYBOARD_ADJACENT = Replacement::KEYBOARD_ADJACENT

      def generate(package_name)
        variants = []

        package_name.each_char.with_index do |char, i|
          adjacent = KEYBOARD_ADJACENT[char.downcase] || []
          adjacent.each do |adj_char|
            variants << package_name[0..i] + adj_char + package_name[(i + 1)..]
            variants << package_name[0...i] + adj_char + package_name[i..]
          end
        end

        variants.uniq
      end
    end
  end
end
