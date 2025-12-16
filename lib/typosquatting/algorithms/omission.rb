# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Omission < Base
      def generate(package_name)
        variants = []
        package_name.length.times do |i|
          variant = package_name[0...i] + package_name[(i + 1)..]
          variants << variant unless variant.empty?
        end
        variants.uniq
      end
    end
  end
end
