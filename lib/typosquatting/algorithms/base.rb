# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Base
      attr_reader :name

      def initialize
        @name = self.class.name.split("::").last.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end

      def generate(package_name)
        raise NotImplementedError, "Subclasses must implement #generate"
      end

      def self.all
        @all ||= [
          Omission.new,
          Repetition.new,
          Replacement.new,
          Transposition.new,
          Addition.new,
          Homoglyph.new,
          VowelSwap.new,
          Delimiter.new,
          WordOrder.new,
          Plural.new,
          Misspelling.new,
          Numeral.new,
          Bitflip.new,
          AdjacentInsertion.new,
          DoubleHit.new,
          Combosquatting.new
        ]
      end
    end
  end
end
