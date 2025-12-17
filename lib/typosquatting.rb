# frozen_string_literal: true

require_relative "typosquatting/version"

require_relative "typosquatting/algorithms/base"
require_relative "typosquatting/algorithms/omission"
require_relative "typosquatting/algorithms/repetition"
require_relative "typosquatting/algorithms/replacement"
require_relative "typosquatting/algorithms/transposition"
require_relative "typosquatting/algorithms/addition"
require_relative "typosquatting/algorithms/homoglyph"
require_relative "typosquatting/algorithms/vowel_swap"
require_relative "typosquatting/algorithms/delimiter"
require_relative "typosquatting/algorithms/word_order"
require_relative "typosquatting/algorithms/plural"
require_relative "typosquatting/algorithms/misspelling"
require_relative "typosquatting/algorithms/numeral"
require_relative "typosquatting/algorithms/bitflip"
require_relative "typosquatting/algorithms/adjacent_insertion"
require_relative "typosquatting/algorithms/double_hit"
require_relative "typosquatting/algorithms/combosquatting"

require_relative "typosquatting/ecosystems/base"
require_relative "typosquatting/ecosystems/pypi"
require_relative "typosquatting/ecosystems/npm"
require_relative "typosquatting/ecosystems/rubygems"
require_relative "typosquatting/ecosystems/cargo"
require_relative "typosquatting/ecosystems/golang"
require_relative "typosquatting/ecosystems/maven"
require_relative "typosquatting/ecosystems/nuget"
require_relative "typosquatting/ecosystems/composer"
require_relative "typosquatting/ecosystems/hex"
require_relative "typosquatting/ecosystems/pub"
require_relative "typosquatting/ecosystems/github_actions"

require_relative "typosquatting/generator"
require_relative "typosquatting/lookup"
require_relative "typosquatting/confusion"
require_relative "typosquatting/sbom"
require_relative "typosquatting/cli"

module Typosquatting
  class Error < StandardError; end

  class << self
    def generate(package_name, ecosystem:)
      generator = Generator.new(ecosystem: ecosystem)
      generator.generate(package_name).map(&:name)
    end

    def generate_with_algorithms(package_name, ecosystem:)
      generator = Generator.new(ecosystem: ecosystem)
      generator.generate(package_name)
    end

    def check(package_name, ecosystem:)
      generator = Generator.new(ecosystem: ecosystem)
      variants = generator.generate(package_name)

      lookup = Lookup.new(ecosystem: ecosystem)
      variants.map do |variant|
        result = lookup.check(variant.name)
        CheckResult.new(
          name: variant.name,
          algorithm: variant.algorithm,
          exists: result.exists?,
          registries: result.packages.map { |p| RegistryInfo.new(p.dig("registry", "name"), p.dig("registry", "url")) }
        )
      end
    end

    def check_confusion(package_name, ecosystem:)
      confusion = Confusion.new(ecosystem: ecosystem)
      confusion.check(package_name)
    end
  end

  CheckResult = Struct.new(:name, :algorithm, :exists, :registries, keyword_init: true) do
    def exists?
      exists
    end

    def to_h
      {
        name: name,
        algorithm: algorithm,
        exists: exists?,
        registries: registries.map(&:to_h)
      }
    end
  end

  RegistryInfo = Struct.new(:name, :url) do
    def to_h
      { name: name, url: url }
    end
  end

  module Ecosystem
    def self.get(name)
      Ecosystems::Base.get(name)
    end

    def self.all
      Ecosystems::Base.all
    end
  end
end
