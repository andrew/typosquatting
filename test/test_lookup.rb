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
end
