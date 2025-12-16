# frozen_string_literal: true

require "test_helper"

class TestHex < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("hex")
  end

  def test_purl_type
    assert_equal "hex", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("phoenix")
    assert @ecosystem.valid_name?("my_package")
    assert @ecosystem.valid_name?("package123")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("my-package")
    refute @ecosystem.valid_name?("my.package")
    refute @ecosystem.valid_name?("123package")
    refute @ecosystem.valid_name?("_package")
  end

  def test_case_insensitive
    refute @ecosystem.case_sensitive?
  end

  def test_allowed_delimiters
    assert_equal %w[_], @ecosystem.allowed_delimiters
  end
end
