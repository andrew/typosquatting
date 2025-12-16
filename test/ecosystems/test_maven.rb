# frozen_string_literal: true

require "test_helper"

class TestMaven < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::Base.get("maven")
  end

  def test_purl_type
    assert_equal "maven", @ecosystem.purl_type
  end

  def test_valid_names
    assert @ecosystem.valid_name?("com.google:guava")
    assert @ecosystem.valid_name?("org.apache.commons:commons-lang3")
    assert @ecosystem.valid_name?("io.netty:netty-all")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("justartifact")
    refute @ecosystem.valid_name?(":artifact")
    refute @ecosystem.valid_name?("group:")
  end

  def test_case_sensitive
    assert @ecosystem.case_sensitive?
  end

  def test_supports_namespaces
    assert @ecosystem.supports_namespaces?
  end

  def test_parse_namespace
    group_id, artifact_id = @ecosystem.parse_namespace("com.google:guava")
    assert_equal "com.google", group_id
    assert_equal "guava", artifact_id
  end

  def test_format_name
    assert_equal "com.google:guava", @ecosystem.format_name("com.google", "guava")
  end
end
