# frozen_string_literal: true

require "test_helper"

class TestPub < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("pub")
  end

  def test_purl_type
    assert_equal "pub", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("flutter")
    assert @ecosystem.valid_name?("my_package")
    assert @ecosystem.valid_name?("package123")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("my-package")
    refute @ecosystem.valid_name?("my.package")
    refute @ecosystem.valid_name?("a")
  end

  def test_max_length
    long_name = "a" * 65
    refute @ecosystem.valid_name?(long_name)

    valid_name = "aa" + "a" * 62
    assert @ecosystem.valid_name?(valid_name)
  end

  def test_case_insensitive
    refute @ecosystem.case_sensitive?
  end

  def test_allowed_delimiters
    assert_equal %w[_], @ecosystem.allowed_delimiters
  end
end
