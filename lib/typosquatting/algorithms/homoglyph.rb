# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Homoglyph < Base
      GLYPHS = {
        "a" => %w[4 @],
        "b" => %w[8 6],
        "c" => %w[( {],
        "e" => %w[3],
        "g" => %w[9 6],
        "i" => %w[1 l | !],
        "l" => %w[1 i | I],
        "o" => %w[0],
        "s" => %w[5 $],
        "t" => %w[7 +],
        "z" => %w[2],
        "0" => %w[o O],
        "1" => %w[l i I |],
        "2" => %w[z Z],
        "3" => %w[e E],
        "4" => %w[a A],
        "5" => %w[s S],
        "6" => %w[b g],
        "7" => %w[t T],
        "8" => %w[b B],
        "9" => %w[g q],
        "rn" => %w[m],
        "m" => %w[rn nn],
        "vv" => %w[w],
        "w" => %w[vv uu],
        "cl" => %w[d],
        "d" => %w[cl]
      }.freeze

      def generate(package_name)
        variants = []

        package_name.each_char.with_index do |char, i|
          glyphs = GLYPHS[char.downcase] || []
          glyphs.each do |glyph|
            variant = package_name[0...i] + glyph + package_name[(i + 1)..]
            variants << variant
          end
        end

        GLYPHS.each do |pattern, replacements|
          next if pattern.length == 1

          if package_name.include?(pattern)
            replacements.each do |replacement|
              variants << package_name.gsub(pattern, replacement)
            end
          end
        end

        variants.uniq
      end
    end
  end
end
