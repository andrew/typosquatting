# frozen_string_literal: true

require "test_helper"

class TestCombosquatting < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Combosquatting.new
  end

  def test_generates_suffix_variants
    variants = @algorithm.generate("lodash")

    assert_includes variants, "lodashjs"
    assert_includes variants, "lodash.js"
    assert_includes variants, "lodash-js"
    assert_includes variants, "lodash-cli"
    assert_includes variants, "lodash-lite"
  end

  def test_generates_prefix_variants
    variants = @algorithm.generate("lodash")

    assert_includes variants, "node-lodash"
    assert_includes variants, "py-lodash"
    assert_includes variants, "js-lodash"
  end

  def test_generates_plural_suffix
    variants = @algorithm.generate("request")

    assert_includes variants, "requests"
  end

  def test_dedupes_results
    variants = @algorithm.generate("test")
    assert_equal variants, variants.uniq
  end

  def test_algorithm_name
    assert_equal "combosquatting", @algorithm.name
  end
end
