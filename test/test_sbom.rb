# frozen_string_literal: true

require "test_helper"
require "json"
require "tempfile"

class TestSBOM < Minitest::Test
  def test_parses_cyclonedx_sbom
    sbom_data = {
      "bomFormat" => "CycloneDX",
      "specVersion" => "1.4",
      "components" => [
        {
          "type" => "library",
          "name" => "requests",
          "version" => "2.28.0",
          "purl" => "pkg:pypi/requests@2.28.0"
        }
      ]
    }

    file = Tempfile.new(["test", ".json"])
    file.write(JSON.generate(sbom_data))
    file.close

    checker = Typosquatting::SBOMChecker.new(file.path)
    assert_equal 1, checker.sbom.packages.length

    file.unlink
  end

  def test_extracts_purl_from_package
    sbom_data = {
      "bomFormat" => "CycloneDX",
      "specVersion" => "1.4",
      "components" => [
        {
          "type" => "library",
          "name" => "requests",
          "version" => "2.28.0",
          "purl" => "pkg:pypi/requests@2.28.0"
        }
      ]
    }

    file = Tempfile.new(["test", ".json"])
    file.write(JSON.generate(sbom_data))
    file.close

    checker = Typosquatting::SBOMChecker.new(file.path)
    pkg = checker.sbom.packages.first
    purl = checker.extract_purl(pkg)

    assert_equal "pkg:pypi/requests@2.28.0", purl

    file.unlink
  end

  def test_check_returns_empty_for_legitimate_packages
    sbom_data = {
      "bomFormat" => "CycloneDX",
      "specVersion" => "1.4",
      "components" => [
        {
          "type" => "library",
          "name" => "requests",
          "version" => "2.28.0",
          "purl" => "pkg:pypi/requests@2.28.0"
        }
      ]
    }

    file = Tempfile.new(["test", ".json"])
    file.write(JSON.generate(sbom_data))
    file.close

    stub_request(:post, "https://packages.ecosyste.ms/api/v1/packages/bulk_lookup")
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    checker = Typosquatting::SBOMChecker.new(file.path)
    results = checker.check

    assert_empty results

    file.unlink
  end

  def test_deduplicates_packages_by_name_and_ecosystem
    sbom_data = {
      "bomFormat" => "CycloneDX",
      "specVersion" => "1.4",
      "components" => [
        {
          "type" => "library",
          "name" => "minipass",
          "version" => "3.3.6",
          "purl" => "pkg:npm/minipass@3.3.6"
        },
        {
          "type" => "library",
          "name" => "minipass",
          "version" => "5.0.0",
          "purl" => "pkg:npm/minipass@5.0.0"
        },
        {
          "type" => "library",
          "name" => "minipass",
          "version" => "7.0.0",
          "purl" => "pkg:npm/minipass@7.0.0"
        }
      ]
    }

    file = Tempfile.new(["test", ".json"])
    file.write(JSON.generate(sbom_data))
    file.close

    checker = Typosquatting::SBOMChecker.new(file.path)
    unique_packages = checker.extract_unique_packages

    assert_equal 1, unique_packages.length
    assert_equal "minipass", unique_packages.values.first[:name]

    file.unlink
  end

  def test_deduplicates_same_package_across_different_ecosystems
    sbom_data = {
      "bomFormat" => "CycloneDX",
      "specVersion" => "1.4",
      "components" => [
        {
          "type" => "library",
          "name" => "requests",
          "version" => "2.28.0",
          "purl" => "pkg:pypi/requests@2.28.0"
        },
        {
          "type" => "library",
          "name" => "requests",
          "version" => "1.0.0",
          "purl" => "pkg:npm/requests@1.0.0"
        }
      ]
    }

    file = Tempfile.new(["test", ".json"])
    file.write(JSON.generate(sbom_data))
    file.close

    checker = Typosquatting::SBOMChecker.new(file.path)
    unique_packages = checker.extract_unique_packages

    assert_equal 2, unique_packages.length
    assert unique_packages.key?("pypi:requests")
    assert unique_packages.key?("npm:requests")

    file.unlink
  end

  def test_sbom_result_struct
    result = Typosquatting::SBOMChecker::SBOMResult.new(
      name: "reqests",
      version: "1.0.0",
      ecosystem: "pypi",
      purl: "pkg:pypi/reqests@1.0.0",
      suspicions: [
        Typosquatting::SBOMChecker::Suspicion.new(
          name: "requests",
          algorithm: "omission",
          registries: ["pypi.org"]
        )
      ]
    )

    assert_equal "reqests", result.name
    assert_equal 1, result.suspicions.length
    assert_equal "requests", result.suspicions.first.name

    hash = result.to_h
    assert_equal "reqests", hash[:name]
    assert_equal 1, hash[:similar_to].length
  end
end
