# frozen_string_literal: true

require "test_helper"

class TestTransposition < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Transposition.new
  end

  def test_swaps_adjacent_characters
    variants = @algorithm.generate("test")

    assert_includes variants, "etst"
    assert_includes variants, "tset"
    assert_includes variants, "tets"
  end

  def test_returns_correct_count
    variants = @algorithm.generate("abcd")
    assert_equal 3, variants.length
  end

  def test_algorithm_name
    assert_equal "transposition", @algorithm.name
  end
end
