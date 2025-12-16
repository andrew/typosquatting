# frozen_string_literal: true

require "test_helper"

class TestNumeral < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Numeral.new
  end

  def test_converts_digit_to_word
    variants = @algorithm.generate("lib2")

    assert_includes variants, "libtwo"
    assert_includes variants, "libsecond"
  end

  def test_converts_word_to_digit
    variants = @algorithm.generate("libtwo")

    assert_includes variants, "lib2"
  end

  def test_handles_for_four
    variants = @algorithm.generate("for")

    assert_includes variants, "4"
    assert_includes variants, "four"
  end

  def test_algorithm_name
    assert_equal "numeral", @algorithm.name
  end
end
