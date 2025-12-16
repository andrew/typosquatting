# frozen_string_literal: true

require "test_helper"

class TestTyposquatting < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Typosquatting::VERSION
  end

  def test_generate_returns_array_of_names
    variants = Typosquatting.generate("requests", ecosystem: "pypi")

    assert variants.is_a?(Array)
    assert variants.all? { |v| v.is_a?(String) }
    assert variants.length > 0
  end

  def test_generate_with_algorithms_returns_variants
    variants = Typosquatting.generate_with_algorithms("requests", ecosystem: "pypi")

    assert variants.is_a?(Array)
    assert variants.all? { |v| v.is_a?(Typosquatting::Generator::Variant) }
    assert variants.first.respond_to?(:name)
    assert variants.first.respond_to?(:algorithm)
  end

  def test_ecosystem_get_returns_ecosystem
    ecosystem = Typosquatting::Ecosystem.get("pypi")

    assert ecosystem.respond_to?(:valid_name?)
    assert ecosystem.respond_to?(:normalise)
  end

  def test_ecosystem_get_raises_for_unknown
    assert_raises(ArgumentError) do
      Typosquatting::Ecosystem.get("unknown")
    end
  end

  def test_check_makes_api_calls
    stub_request(:get, /packages.ecosyste.ms/)
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    results = Typosquatting.check("test", ecosystem: "pypi")

    assert results.is_a?(Array)
    assert results.all? { |r| r.is_a?(Typosquatting::CheckResult) }
  end

  def test_check_confusion_returns_result
    stub_request(:get, /packages.ecosyste.ms\/api\/v1\/packages/)
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, /packages.ecosyste.ms\/api\/v1\/registries/)
      .to_return(
        status: 200,
        body: [{ "name" => "pypi.org" }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = Typosquatting.check_confusion("test", ecosystem: "pypi")

    assert result.respond_to?(:confusion_risk?)
    assert result.respond_to?(:registries)
  end
end
