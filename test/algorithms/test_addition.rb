# frozen_string_literal: true

require "test_helper"

class TestAddition < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Addition.new
  end

  def test_adds_characters_at_start
    variants = @algorithm.generate("test")

    assert_includes variants, "atest"
    assert_includes variants, "1test"
  end

  def test_adds_characters_at_end
    variants = @algorithm.generate("test")

    assert_includes variants, "testa"
    assert_includes variants, "test1"
  end

  def test_algorithm_name
    assert_equal "addition", @algorithm.name
  end
end
