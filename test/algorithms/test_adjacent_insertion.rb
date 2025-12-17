# frozen_string_literal: true

require "test_helper"

class TestAdjacentInsertion < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::AdjacentInsertion.new
  end

  def test_generates_variants_with_inserted_adjacent_keys
    variants = @algorithm.generate("test")

    assert_includes variants, "testr"
    assert_includes variants, "tesyt"
    assert_includes variants, "trest"
  end

  def test_inserts_before_and_after_each_character
    variants = @algorithm.generate("ab")

    assert variants.any? { |v| v.length == 3 }
  end

  def test_uses_keyboard_adjacent_mapping
    variants = @algorithm.generate("q")

    assert_includes variants, "qw"
    assert_includes variants, "wq"
    assert_includes variants, "qa"
    assert_includes variants, "aq"
  end

  def test_dedupes_results
    variants = @algorithm.generate("test")
    assert_equal variants, variants.uniq
  end

  def test_algorithm_name
    assert_equal "adjacent_insertion", @algorithm.name
  end
end
