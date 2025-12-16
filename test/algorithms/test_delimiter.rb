# frozen_string_literal: true

require "test_helper"

class TestDelimiter < Minitest::Test
  def setup
    @algorithm = Typosquatting::Algorithms::Delimiter.new
  end

  def test_swaps_hyphens_to_underscores
    variants = @algorithm.generate("my-package")

    assert_includes variants, "my_package"
  end

  def test_swaps_underscores_to_hyphens
    variants = @algorithm.generate("my_package")

    assert_includes variants, "my-package"
  end

  def test_removes_delimiters
    variants = @algorithm.generate("my-package")

    assert_includes variants, "mypackage"
  end

  def test_adds_delimiters
    variants = @algorithm.generate("mypackage")

    assert_includes variants, "my-package"
    assert_includes variants, "my_package"
    assert_includes variants, "myp-ackage"
  end

  def test_handles_dots
    variants = @algorithm.generate("my.package")

    assert_includes variants, "my-package"
    assert_includes variants, "my_package"
    assert_includes variants, "mypackage"
  end

  def test_algorithm_name
    assert_equal "delimiter", @algorithm.name
  end
end
