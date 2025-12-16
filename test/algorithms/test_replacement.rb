# frozen_string_literal: true

require "test_helper"

class TestReplacement < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Replacement.new
  end

  def test_generates_variants_with_adjacent_keys
    variants = @algorithm.generate("test")

    assert_includes variants, "rest"
    assert_includes variants, "yest"
    assert_includes variants, "twst"
    assert_includes variants, "trst"
  end

  def test_handles_numbers
    variants = @algorithm.generate("test2")
    assert_includes variants, "test1"
    assert_includes variants, "test3"
  end

  def test_algorithm_name
    assert_equal "replacement", @algorithm.name
  end
end
