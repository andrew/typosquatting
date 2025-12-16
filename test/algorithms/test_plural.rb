# frozen_string_literal: true

require "test_helper"

class TestPlural < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Plural.new
  end

  def test_pluralizes_regular_words
    variants = @algorithm.generate("request")

    assert_includes variants, "requests"
  end

  def test_singularizes_plural_words
    variants = @algorithm.generate("requests")

    assert_includes variants, "request"
  end

  def test_handles_words_ending_in_y
    variants = @algorithm.generate("library")

    assert_includes variants, "libraries"
  end

  def test_handles_words_ending_in_ss
    variants = @algorithm.generate("class")

    assert_includes variants, "classes"
  end

  def test_handles_irregular_plurals
    variants = @algorithm.generate("index")

    assert_includes variants, "indices"
  end

  def test_algorithm_name
    assert_equal "plural", @algorithm.name
  end
end
