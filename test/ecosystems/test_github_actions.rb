# frozen_string_literal: true

require "test_helper"

class TestGithubActions < Minitest::Test
  def setup
    @ecosystem = Typosquatting::Ecosystems::GithubActions.new
  end

  def test_valid_action_names
    assert @ecosystem.valid_name?("actions/checkout")
    assert @ecosystem.valid_name?("github/codeql-action")
    assert @ecosystem.valid_name?("docker/build-push-action")
    assert @ecosystem.valid_name?("aws-actions/configure-aws-credentials")
  end

  def test_valid_with_version_ref
    assert @ecosystem.valid_name?("actions/checkout@v4")
    assert @ecosystem.valid_name?("actions/checkout@main")
    assert @ecosystem.valid_name?("actions/checkout@abc123")
  end

  def test_invalid_names
    refute @ecosystem.valid_name?("")
    refute @ecosystem.valid_name?(nil)
    refute @ecosystem.valid_name?("checkout")
    refute @ecosystem.valid_name?("-actions/checkout")
    refute @ecosystem.valid_name?("actions-/checkout")
    refute @ecosystem.valid_name?("act--ions/checkout")
    refute @ecosystem.valid_name?("actions/.checkout")
  end

  def test_normalise_strips_version
    assert_equal "actions/checkout", @ecosystem.normalise("actions/checkout@v4")
    assert_equal "actions/checkout", @ecosystem.normalise("actions/checkout@main")
  end

  def test_normalise_lowercases
    assert_equal "actions/checkout", @ecosystem.normalise("Actions/Checkout")
  end

  def test_parse_namespace
    owner, repo = @ecosystem.parse_namespace("actions/checkout")
    assert_equal "actions", owner
    assert_equal "checkout", repo
  end

  def test_parse_namespace_with_version
    owner, repo = @ecosystem.parse_namespace("actions/checkout@v4")
    assert_equal "actions", owner
    assert_equal "checkout", repo
  end

  def test_format_name
    assert_equal "actions/checkout", @ecosystem.format_name("actions", "checkout")
  end

  def test_supports_namespaces
    assert @ecosystem.supports_namespaces?
  end

  def test_case_insensitive
    refute @ecosystem.case_sensitive?
  end

  def test_owner_max_length
    long_owner = "a" * 40
    refute @ecosystem.valid_name?("#{long_owner}/checkout")

    valid_owner = "a" * 39
    assert @ecosystem.valid_name?("#{valid_owner}/checkout")
  end

  def test_repo_max_length
    long_repo = "a" * 101
    refute @ecosystem.valid_name?("actions/#{long_repo}")

    valid_repo = "a" * 100
    assert @ecosystem.valid_name?("actions/#{valid_repo}")
  end

  def test_purl_type
    assert_equal "github", @ecosystem.purl_type
  end
end
