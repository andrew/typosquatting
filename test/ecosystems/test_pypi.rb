# frozen_string_literal: true

require "test_helper"

class TestPypi < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("pypi")
  end

  def test_purl_type
    assert_equal "pypi", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("requests")
    assert @ecosystem.valid_name?("my-package")
    assert @ecosystem.valid_name?("my_package")
    assert @ecosystem.valid_name?("my.package")
    assert @ecosystem.valid_name?("package123")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("-package")
    refute @ecosystem.valid_name?("package-")
  end

  def test_case_insensitive
    refute @ecosystem.case_sensitive?
  end

  def test_normalisation_lowercases
    assert_equal "requests", @ecosystem.normalise("REQUESTS")
    assert_equal "requests", @ecosystem.normalise("Requests")
  end

  def test_normalisation_collapses_delimiters
    assert_equal "my-package", @ecosystem.normalise("my-package")
    assert_equal "my-package", @ecosystem.normalise("my_package")
    assert_equal "my-package", @ecosystem.normalise("my.package")
    assert_equal "my-package", @ecosystem.normalise("my--package")
    assert_equal "my-package", @ecosystem.normalise("my_.package")
  end

  def test_equivalent_names
    assert @ecosystem.equivalent?("my-package", "my_package")
    assert @ecosystem.equivalent?("my-package", "my.package")
    assert @ecosystem.equivalent?("MY-PACKAGE", "my_package")
  end

  def test_allowed_delimiters
    assert_equal %w[- _ .], @ecosystem.allowed_delimiters
  end
end
