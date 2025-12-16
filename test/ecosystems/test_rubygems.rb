# frozen_string_literal: true

require "test_helper"

class TestRubygems < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("gem")
  end

  def test_purl_type
    assert_equal "gem", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("rails")
    assert @ecosystem.valid_name?("my-gem")
    assert @ecosystem.valid_name?("my_gem")
    assert @ecosystem.valid_name?("gem123")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("my.gem")
    refute @ecosystem.valid_name?("-gem")
  end

  def test_case_sensitive
    assert @ecosystem.case_sensitive?
  end

  def test_no_normalisation
    assert_equal "MyGem", @ecosystem.normalise("MyGem")
    assert_equal "my-gem", @ecosystem.normalise("my-gem")
  end

  def test_allowed_delimiters
    assert_equal %w[- _], @ecosystem.allowed_delimiters
  end
end
