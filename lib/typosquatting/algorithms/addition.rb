# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Addition < Base
      CHARS = ("a".."z").to_a + ("0".."9").to_a

      def generate(package_name)
        variants = []

        CHARS.each do |char|
          variants << char + package_name
          variants << package_name + char
        end

        variants.uniq
      end
    end
  end
end
