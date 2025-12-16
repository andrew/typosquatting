# frozen_string_literal: true

require "test_helper"

class TestOmission < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Omission.new
  end

  def test_generates_variants_by_dropping_characters
    variants = @algorithm.generate("requests")

    assert_includes variants, "equests"
    assert_includes variants, "rquests"
    assert_includes variants, "reuests"
    assert_includes variants, "reqests"
    assert_includes variants, "requsts"
    assert_includes variants, "requets"
    assert_includes variants, "request"
  end

  def test_returns_correct_count
    variants = @algorithm.generate("test")
    assert_equal 4, variants.length
  end

  def test_handles_short_names
    variants = @algorithm.generate("ab")
    assert_equal 2, variants.length
    assert_includes variants, "b"
    assert_includes variants, "a"
  end

  def test_handles_single_character
    variants = @algorithm.generate("a")
    assert_empty variants
  end

  def test_dedupes_results
    variants = @algorithm.generate("aaa")
    assert_equal 1, variants.uniq.length
  end

  def test_algorithm_name
    assert_equal "omission", @algorithm.name
  end
end
