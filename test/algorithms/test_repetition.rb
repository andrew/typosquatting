# frozen_string_literal: true

require "test_helper"

class TestRepetition < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Repetition.new
  end

  def test_generates_variants_by_doubling_characters
    variants = @algorithm.generate("test")

    assert_includes variants, "ttest"
    assert_includes variants, "teest"
    assert_includes variants, "tesst"
    assert_includes variants, "testt"
  end

  def test_returns_correct_count
    variants = @algorithm.generate("abc")
    assert_equal 3, variants.length
  end

  def test_algorithm_name
    assert_equal "repetition", @algorithm.name
  end
end
