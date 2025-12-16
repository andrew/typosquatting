# frozen_string_literal: true

require "test_helper"

class TestHomoglyph < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Homoglyph.new
  end

  def test_replaces_with_lookalike_characters
    variants = @algorithm.generate("test")

    assert_includes variants, "t3st"
    assert_includes variants, "7est"
  end

  def test_handles_o_zero_substitution
    variants = @algorithm.generate("foo")

    assert_includes variants, "f0o"
    assert_includes variants, "fo0"
  end

  def test_handles_l_one_substitution
    variants = @algorithm.generate("lib")

    assert_includes variants, "1ib"
    assert_includes variants, "iib"
  end

  def test_handles_multi_char_patterns
    variants = @algorithm.generate("modern")

    assert_includes variants, "rnodern"
  end

  def test_algorithm_name
    assert_equal "homoglyph", @algorithm.name
  end
end
