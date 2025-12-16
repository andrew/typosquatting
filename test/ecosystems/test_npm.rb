# frozen_string_literal: true

require "test_helper"

class TestNpm < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("npm")
  end

  def test_purl_type
    assert_equal "npm", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("lodash")
    assert @ecosystem.valid_name?("my-package")
    assert @ecosystem.valid_name?("my_package")
    assert @ecosystem.valid_name?("my.package")
    assert @ecosystem.valid_name?("package123")
  end

  def test_valid_scoped_names
    assert @ecosystem.valid_name?("@types/node")
    assert @ecosystem.valid_name?("@angular/core")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?(".package")
    refute @ecosystem.valid_name?("_package")
    refute @ecosystem.valid_name?("PACKAGE")
  end

  def test_case_insensitive
    refute @ecosystem.case_sensitive?
  end

  def test_supports_namespaces
    assert @ecosystem.supports_namespaces?
  end

  def test_parse_namespace_scoped
    namespace, name = @ecosystem.parse_namespace("@types/node")
    assert_equal "@types", namespace
    assert_equal "node", name
  end

  def test_parse_namespace_unscoped
    namespace, name = @ecosystem.parse_namespace("lodash")
    assert_nil namespace
    assert_equal "lodash", name
  end
end
