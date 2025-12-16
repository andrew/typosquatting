# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Plural < Base
      IRREGULAR_PLURALS = {
        "child" => "children",
        "person" => "people",
        "man" => "men",
        "woman" => "women",
        "foot" => "feet",
        "tooth" => "teeth",
        "goose" => "geese",
        "mouse" => "mice",
        "ox" => "oxen",
        "index" => "indices",
        "matrix" => "matrices",
        "vertex" => "vertices",
        "analysis" => "analyses",
        "basis" => "bases",
        "crisis" => "crises",
        "datum" => "data",
        "medium" => "media",
        "criterion" => "criteria"
      }.freeze

      def generate(package_name)
        variants = []

        variants << pluralize(package_name)
        variants << singularize(package_name)

        variants.compact.reject { |v| v == package_name }.uniq
      end

      def pluralize(word)
        return IRREGULAR_PLURALS[word] if IRREGULAR_PLURALS.key?(word)

        case word
        when /(.*)([^aeiou])y$/
          "#{$1}#{$2}ies"
        when /(.*)(ss|x|z|ch|sh)$/
          "#{word}es"
        when /(.*)fe$/
          "#{$1}ves"
        when /(.*)f$/
          "#{$1}ves"
        when /(.*)s$/
          "#{word}es"
        else
          "#{word}s"
        end
      end

      def singularize(word)
        reverse_irregulars = IRREGULAR_PLURALS.invert
        return reverse_irregulars[word] if reverse_irregulars.key?(word)

        case word
        when /(.*)ies$/
          "#{$1}y"
        when /(.*)ves$/
          "#{$1}f"
        when /(.*)(ses|xes|zes|ches|shes)$/
          word[0..-3]
        when /(.*)s$/
          $1
        else
          word
        end
      end
    end
  end
end
