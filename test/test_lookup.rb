# frozen_string_literal: true

require "test_helper"

class TestLookup < Minitest::Test
  def setup
    @lookup = Typosquatting::Lookup.new(ecosystem: "pypi")
  end

  def test_builds_purl_for_simple_name
    purl = @lookup.build_purl("requests")
    assert_equal "pkg:pypi/requests", purl.to_s
  end

  def test_builds_purl_for_npm_scoped_package
    lookup = Typosquatting::Lookup.new(ecosystem: "npm")
    purl = lookup.build_purl("@types/node")
    assert_equal "pkg:npm/%40types/node", purl.to_s
  end

  def test_builds_purl_for_maven_package
    lookup = Typosquatting::Lookup.new(ecosystem: "maven")
    purl = lookup.build_purl("com.google:guava")
    assert_equal "pkg:maven/com.google/guava", purl.to_s
  end

  def test_check_returns_result_for_existing_package
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:pypi/requests")
      .to_return(
        status: 200,
        body: [{ "name" => "requests", "registry" => { "name" => "pypi.org" } }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @lookup.check("requests")

    assert result.exists?
    assert_equal "requests", result.name
    assert_includes result.registries, "pypi.org"
  end

  def test_check_returns_result_for_nonexistent_package
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:pypi/nonexistent-pkg-12345")
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @lookup.check("nonexistent-pkg-12345")

    refute result.exists?
    assert_empty result.registries
  end

  def test_check_handles_api_error
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:pypi/test")
      .to_return(status: 500, body: "Internal Server Error")

    assert_raises(Typosquatting::APIError) do
      @lookup.check("test")
    end
  end

  def test_registries_returns_list
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries?ecosystem=pypi")
      .to_return(
        status: 200,
        body: [
          { "name" => "pypi.org", "url" => "https://pypi.org", "ecosystem" => "pypi" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    registries = @lookup.registries

    assert_equal 1, registries.length
    assert_equal "pypi.org", registries.first.name
  end

  def test_includes_user_agent
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:pypi/test")
      .with(headers: { "User-Agent" => /typosquatting-ruby/ })
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    @lookup.check("test")

    assert_requested(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:pypi/test")
  end

  def test_list_names_with_prefix
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/pypi.org/package_names?prefix=req")
      .to_return(
        status: 200,
        body: ["requests", "reqests", "request"].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    names = @lookup.list_names(registry: "pypi.org", prefix: "req")

    assert_equal 3, names.length
    assert_includes names, "requests"
  end

  def test_list_names_with_postfix
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/pypi.org/package_names?postfix=ests")
      .to_return(
        status: 200,
        body: ["requests", "reqests", "tests"].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    names = @lookup.list_names(registry: "pypi.org", postfix: "ests")

    assert_equal 3, names.length
    assert_includes names, "requests"
  end

  def test_list_names_with_both_prefix_and_postfix
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/pypi.org/package_names?prefix=req&postfix=ests")
      .to_return(
        status: 200,
        body: ["requests", "reqests"].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    names = @lookup.list_names(registry: "pypi.org", prefix: "req", postfix: "ests")

    assert_equal 2, names.length
  end

  def test_levenshtein_distance
    assert_equal 0, @lookup.levenshtein("test", "test")
    assert_equal 1, @lookup.levenshtein("test", "tests")
    assert_equal 1, @lookup.levenshtein("test", "tst")
    assert_equal 1, @lookup.levenshtein("test", "tezt")
    assert_equal 1, @lookup.levenshtein("test", "best")
    assert_equal 2, @lookup.levenshtein("requests", "reqeusts")
  end

  def test_discover_returns_similar_packages
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries?ecosystem=pypi")
      .to_return(
        status: 200,
        body: [{ "name" => "pypi.org" }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/pypi.org/package_names?prefix=req")
      .to_return(
        status: 200,
        body: ["requests", "reqests", "request", "requets", "require"].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    results = @lookup.discover("requests", max_distance: 2)

    assert results.length > 0
    assert results.all? { |r| r.distance <= 2 }
    assert results.none? { |r| r.name == "requests" }
    assert results.any? { |r| r.name == "reqests" }
  end

  def test_check_with_variants_finds_existing
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries?ecosystem=pypi")
      .to_return(
        status: 200,
        body: [{ "name" => "pypi.org" }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries/pypi.org/package_names?prefix=req")
      .to_return(
        status: 200,
        body: ["requests", "reqests", "request"].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    variants = ["reqests", "requets", "rquests"]
    results = @lookup.check_with_variants("requests", variants)

    assert_equal 3, results.length
    assert results.find { |r| r.name == "reqests" }.exists?
    refute results.find { |r| r.name == "requets" }.exists?
  end
end
