# frozen_string_literal: true

require "test_helper"

class TestBitflip < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Bitflip.new
  end

  def test_generates_variants_by_flipping_bits
    variants = @algorithm.generate("google")

    assert_includes variants, "coogle"
    assert_includes variants, "ooogle"
    assert_includes variants, "gokgle"
    assert_includes variants, "googlg"
  end

  def test_filters_invalid_characters
    variants = @algorithm.generate("test")

    variants.each do |v|
      assert_match(/\A[a-z0-9_-]+\z/, v)
    end
  end

  def test_handles_numbers
    variants = @algorithm.generate("test1")

    assert_includes variants, "test0"
    assert_includes variants, "test3"
    assert_includes variants, "test5"
  end

  def test_dedupes_results
    variants = @algorithm.generate("test")
    assert_equal variants, variants.uniq
  end

  def test_algorithm_name
    assert_equal "bitflip", @algorithm.name
  end

  def test_bitflip_char_returns_all_single_bit_flips
    flipped = @algorithm.bitflip_char("a")

    assert flipped.is_a?(Array)
    assert flipped.length > 0
    refute_includes flipped, "a"
  end
end
