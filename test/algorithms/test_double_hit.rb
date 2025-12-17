# frozen_string_literal: true

require "test_helper"

class TestDoubleHit < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::DoubleHit.new
  end

  def test_generates_variants_for_consecutive_identical_chars
    variants = @algorithm.generate("google")

    assert_includes variants, "giigle"
    assert_includes variants, "gppgle"
  end

  def test_returns_empty_for_no_consecutive_chars
    variants = @algorithm.generate("test")

    assert_empty variants
  end

  def test_handles_multiple_consecutive_pairs
    variants = @algorithm.generate("aabbcc")

    assert variants.length > 0
    assert variants.any? { |v| v.start_with?("ss") || v.start_with?("qq") }
  end

  def test_dedupes_results
    variants = @algorithm.generate("google")
    assert_equal variants, variants.uniq
  end

  def test_algorithm_name
    assert_equal "double_hit", @algorithm.name
  end
end
