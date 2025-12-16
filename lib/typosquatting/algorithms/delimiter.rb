# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Delimiter < Base
      DELIMITERS = %w[- _ .].freeze

      def generate(package_name)
        variants = []

        DELIMITERS.each do |from_delim|
          next unless package_name.include?(from_delim)

          DELIMITERS.each do |to_delim|
            next if from_delim == to_delim

            variants << package_name.gsub(from_delim, to_delim)

            current = package_name
            while current.include?(from_delim)
              current = current.sub(from_delim, to_delim)
              variants << current unless current == package_name.gsub(from_delim, to_delim)
            end
          end

          variants << package_name.gsub(from_delim, "")

          current = package_name
          while current.include?(from_delim)
            current = current.sub(from_delim, "")
            variants << current
          end
        end

        DELIMITERS.each do |delim|
          (1...package_name.length).each do |i|
            next if DELIMITERS.include?(package_name[i - 1]) || DELIMITERS.include?(package_name[i])

            variant = package_name[0...i] + delim + package_name[i..]
            variants << variant
          end
        end

        variants.uniq
      end
    end
  end
end
