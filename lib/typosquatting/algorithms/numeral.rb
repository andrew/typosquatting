# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Numeral < Base
      NUMERALS = {
        "0" => %w[zero],
        "1" => %w[one first],
        "2" => %w[two second],
        "3" => %w[three third],
        "4" => %w[four fourth for],
        "5" => %w[five fifth],
        "6" => %w[six sixth],
        "7" => %w[seven seventh],
        "8" => %w[eight eighth],
        "9" => %w[nine ninth],
        "10" => %w[ten tenth]
      }.freeze

      def generate(package_name)
        variants = []

        NUMERALS.each do |digit, words|
          if package_name.include?(digit)
            words.each do |word|
              variants << package_name.gsub(digit, word)
            end
          end

          words.each do |word|
            if package_name.include?(word)
              variants << package_name.gsub(word, digit)

              (words - [word]).each do |other_word|
                variants << package_name.gsub(word, other_word)
              end
            end
          end
        end

        variants.reject { |v| v == package_name }.uniq
      end
    end
  end
end
