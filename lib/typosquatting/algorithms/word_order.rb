# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class WordOrder < Base
      DELIMITERS = %w[- _ .].freeze

      def generate(package_name)
        variants = []

        DELIMITERS.each do |delim|
          parts = package_name.split(delim)
          next if parts.length < 2

          (0...parts.length).to_a.permutation.each do |perm|
            reordered = perm.map { |i| parts[i] }.join(delim)
            variants << reordered unless reordered == package_name
          end
        end

        variants.uniq
      end
    end
  end
end
