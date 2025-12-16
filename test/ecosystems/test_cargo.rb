# frozen_string_literal: true

require "test_helper"

class TestCargo < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("cargo")
  end

  def test_purl_type
    assert_equal "cargo", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("rand")
    assert @ecosystem.valid_name?("my-crate")
    assert @ecosystem.valid_name?("my_crate")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("123crate")
    refute @ecosystem.valid_name?("-crate")
  end

  def test_case_insensitive
    refute @ecosystem.case_sensitive?
  end

  def test_normalisation
    assert_equal "my-crate", @ecosystem.normalise("my-crate")
    assert_equal "my-crate", @ecosystem.normalise("my_crate")
    assert_equal "my-crate", @ecosystem.normalise("MY_CRATE")
  end

  def test_equivalent_names
    assert @ecosystem.equivalent?("my-crate", "my_crate")
    assert @ecosystem.equivalent?("MY-CRATE", "my_crate")
  end

  def test_max_length
    long_name = "a" * 65
    refute @ecosystem.valid_name?(long_name)

    valid_name = "a" * 64
    assert @ecosystem.valid_name?(valid_name)
  end
end
