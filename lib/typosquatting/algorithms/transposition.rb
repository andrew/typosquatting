# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Transposition < Base
      def generate(package_name)
        variants = []
        (package_name.length - 1).times do |i|
          chars = package_name.chars
          chars[i], chars[i + 1] = chars[i + 1], chars[i]
          variants << chars.join
        end
        variants.uniq
      end
    end
  end
end
