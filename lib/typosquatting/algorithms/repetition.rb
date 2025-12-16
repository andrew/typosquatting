# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Repetition < Base
      def generate(package_name)
        variants = []
        package_name.each_char.with_index do |char, i|
          variant = package_name[0..i] + char + package_name[(i + 1)..]
          variants << variant
        end
        variants.uniq
      end
    end
  end
end
