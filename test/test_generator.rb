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

  def test_generates_vendor_variants_for_composer
    generator = Typosquatting::Generator.new(ecosystem: "composer")
    variants = generator.generate("monolog/monolog")

    vendor_variants = variants.select { |v| v.name.end_with?("/monolog") }
    package_variants = variants.select { |v| v.name.start_with?("monolog/") && v.name != "monolog/monolog" }

    assert vendor_variants.length > 0, "Should generate vendor typosquats"
    assert package_variants.length > 0, "Should generate package typosquats"
  end

  def test_generates_owner_variants_for_golang
    generator = Typosquatting::Generator.new(ecosystem: "golang")
    variants = generator.generate("github.com/gorilla/mux")

    owner_variants = variants.select { |v| v.name.end_with?("/mux") && v.name.include?("github.com/") }
    repo_variants = variants.select { |v| v.name.start_with?("github.com/gorilla/") }

    assert owner_variants.length > 0, "Should generate owner typosquats"
    assert repo_variants.length > 0, "Should generate repo typosquats"
  end

  def test_generates_scope_variants_for_npm
    generator = Typosquatting::Generator.new(ecosystem: "npm")
    variants = generator.generate("@angular/core")

    scope_variants = variants.select { |v| v.name.end_with?("/core") }
    package_variants = variants.select { |v| v.name.start_with?("@angular/") }

    assert scope_variants.length > 0, "Should generate scope typosquats"
    assert package_variants.length > 0, "Should generate package typosquats"
  end

  def test_non_namespaced_npm_packages_work
    generator = Typosquatting::Generator.new(ecosystem: "npm")
    variants = generator.generate("lodash")

    assert variants.length > 0
    assert variants.all? { |v| !v.name.include?("/") }
  end

  def test_short_names_use_limited_algorithms
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("aws")

    algorithms_used = variants.map(&:algorithm).uniq
    high_confidence = Typosquatting::Generator::HIGH_CONFIDENCE_ALGORITHMS

    algorithms_used.each do |algo|
      assert_includes high_confidence, algo, "Short name should only use high-confidence algorithms"
    end
  end

  def test_long_names_use_all_algorithms
    generator = Typosquatting::Generator.new(ecosystem: "pypi")
    variants = generator.generate("requests")

    algorithms_used = variants.map(&:algorithm).uniq

    assert algorithms_used.length > Typosquatting::Generator::HIGH_CONFIDENCE_ALGORITHMS.length,
           "Long names should use more than just high-confidence algorithms"
  end

  def test_length_filtering_can_be_disabled
    generator = Typosquatting::Generator.new(ecosystem: "pypi", length_filtering: false)
    variants = generator.generate("aws")

    algorithms_used = variants.map(&:algorithm).uniq

    assert algorithms_used.length > Typosquatting::Generator::HIGH_CONFIDENCE_ALGORITHMS.length,
           "Disabling length filtering should allow all algorithms"
  end

  def test_algorithms_for_length_returns_filtered_for_short
    generator = Typosquatting::Generator.new(ecosystem: "pypi")

    short_algos = generator.algorithms_for_length(3)
    long_algos = generator.algorithms_for_length(10)

    assert short_algos.length < long_algos.length
  end

  def test_threshold_is_five_characters
    generator = Typosquatting::Generator.new(ecosystem: "pypi")

    four_char_algos = generator.algorithms_for_length(4)
    five_char_algos = generator.algorithms_for_length(5)

    assert four_char_algos.length < five_char_algos.length,
           "4-char names should use fewer algorithms than 5-char names"
  end
end
