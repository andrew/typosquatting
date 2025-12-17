# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Bitflip < Base
      VALID_CHARS = (("a".."z").to_a + ("0".."9").to_a + %w[- _]).freeze

      def generate(package_name)
        variants = []

        package_name.each_char.with_index do |char, i|
          flipped = bitflip_char(char)
          flipped.each do |new_char|
            next unless VALID_CHARS.include?(new_char)

            variant = package_name[0...i] + new_char + package_name[(i + 1)..]
            variants << variant
          end
        end

        variants.uniq
      end

      def bitflip_char(char)
        byte = char.ord
        results = []

        8.times do |bit|
          flipped_byte = byte ^ (1 << bit)
          next if flipped_byte > 127 || flipped_byte < 32

          results << flipped_byte.chr
        end

        results.reject { |c| c == char }
      end
    end
  end
end
