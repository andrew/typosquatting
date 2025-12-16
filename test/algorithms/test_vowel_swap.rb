# frozen_string_literal: true

require "test_helper"

class TestVowelSwap < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::VowelSwap.new
  end

  def test_swaps_vowels
    variants = @algorithm.generate("test")

    assert_includes variants, "tast"
    assert_includes variants, "tist"
    assert_includes variants, "tost"
    assert_includes variants, "tust"
    assert_includes variants, "tyst"
  end

  def test_swaps_each_vowel_position
    variants = @algorithm.generate("requests")

    assert_includes variants, "raquests"
    assert_includes variants, "requasts"
  end

  def test_algorithm_name
    assert_equal "vowel_swap", @algorithm.name
  end
end
