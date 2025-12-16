# frozen_string_literal: true

require "test_helper"

class TestGenerator < Minitest::Test
  def test_generates_variants_for_pypi
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("requests")

    assert variants.length > 0
    assert variants.all? { |v| v.is_a?(Typosquatting::Generator::Variant) }
  end

  def test_excludes_original_name
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("requests")

    refute variants.any? { |v| v.name == "requests" }
  end

  def test_excludes_invalid_names
    generator = Typosquatting::Generator.new(ecosystem: "rubygems")
    variants = generator.generate("my-gem")

    refute variants.any? { |v| v.name.include?(".") }
  end

  def test_excludes_normalised_duplicates_for_pypi
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("my-package")

    normalised_names = variants.map { |v| v.name.downcase.gsub(/[-_.]+/, "-") }
    assert_equal normalised_names.uniq.length, normalised_names.length
  end

  def test_variant_includes_algorithm_name
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("requests")

    algorithms_used = variants.map(&:algorithm).uniq
    assert algorithms_used.length > 1
  end

  def test_variant_includes_original
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("requests")

    assert variants.all? { |v| v.original == "requests" }
  end

  def test_can_use_specific_algorithms
    omission = Typosquatting::Algorithms::Omission.new
    generator = Typosquatting::Generator.new(ecosystem: "pypi", algorithms: [omission])
    variants = generator.generate("test")

    assert variants.all? { |v| v.algorithm == "omission" }
  end

  def test_dedupes_by_normalised_name
    generator = Typosquatting::Generator.new(ecosystem: "pypi")

    variants = [
      Typosquatting::Generator::Variant.new(name: "my-pkg", algorithm: "a", original: "test"),
      Typosquatting::Generator::Variant.new(name: "my_pkg", algorithm: "b", original: "test")
    ]

    deduped = generator.dedupe_by_normalised_name(variants)
    assert_equal 1, deduped.length
  end
end
