# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Replacement < Base
      KEYBOARD_ADJACENT = {
        "q" => %w[w a s],
        "w" => %w[q e a s d],
        "e" => %w[w r s d f],
        "r" => %w[e t d f g],
        "t" => %w[r y f g h],
        "y" => %w[t u g h j],
        "u" => %w[y i h j k],
        "i" => %w[u o j k l],
        "o" => %w[i p k l],
        "p" => %w[o l],
        "a" => %w[q w s z],
        "s" => %w[q w e a d z x],
        "d" => %w[w e r s f x c],
        "f" => %w[e r t d g c v],
        "g" => %w[r t y f h v b],
        "h" => %w[t y u g j b n],
        "j" => %w[y u i h k n m],
        "k" => %w[u i o j l m],
        "l" => %w[i o p k],
        "z" => %w[a s x],
        "x" => %w[s d z c],
        "c" => %w[d f x v],
        "v" => %w[f g c b],
        "b" => %w[g h v n],
        "n" => %w[h j b m],
        "m" => %w[j k n],
        "1" => %w[2 q],
        "2" => %w[1 3 q w],
        "3" => %w[2 4 w e],
        "4" => %w[3 5 e r],
        "5" => %w[4 6 r t],
        "6" => %w[5 7 t y],
        "7" => %w[6 8 y u],
        "8" => %w[7 9 u i],
        "9" => %w[8 0 i o],
        "0" => %w[9 o p]
      }.freeze

      def generate(package_name)
        variants = []
        package_name.each_char.with_index do |char, i|
          adjacent = KEYBOARD_ADJACENT[char.downcase] || []
          adjacent.each do |replacement|
            replacement = replacement.upcase if char == char.upcase && char =~ /[a-z]/i
            variant = package_name[0...i] + replacement + package_name[(i + 1)..]
            variants << variant
          end
        end
        variants.uniq
      end
    end
  end
end
