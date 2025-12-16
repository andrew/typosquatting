# frozen_string_literal: true

require "test_helper"

class TestWordOrder < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::WordOrder.new
  end

  def test_swaps_word_order_with_hyphen
    variants = @algorithm.generate("foo-bar")

    assert_includes variants, "bar-foo"
  end

  def test_swaps_word_order_with_underscore
    variants = @algorithm.generate("foo_bar")

    assert_includes variants, "bar_foo"
  end

  def test_handles_multiple_words
    variants = @algorithm.generate("a-b-c")

    assert_includes variants, "a-c-b"
    assert_includes variants, "b-a-c"
    assert_includes variants, "b-c-a"
    assert_includes variants, "c-a-b"
    assert_includes variants, "c-b-a"
  end

  def test_returns_empty_for_single_word
    variants = @algorithm.generate("package")

    assert_empty variants
  end

  def test_algorithm_name
    assert_equal "word_order", @algorithm.name
  end
end
