# frozen_string_literal: true

require "test_helper"

class TestConfusion < Minitest::Test
  def setup
    @confusion = Typosquatting::Confusion.new(ecosystem: "maven")
  end

  def test_detects_confusion_risk
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:maven/com.example/internal")
      .to_return(
        status: 200,
        body: [
          { "name" => "com.example:internal", "registry" => { "name" => "Maven Central" } }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries?ecosystem=maven")
      .to_return(
        status: 200,
        body: [
          { "name" => "Maven Central", "url" => "https://repo1.maven.org/maven2" },
          { "name" => "Google Maven", "url" => "https://maven.google.com" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @confusion.check("com.example:internal")

    assert result.confusion_risk?
    assert_includes result.present_registries, "Maven Central"
    assert_includes result.absent_registries, "Google Maven"
  end

  def test_no_confusion_when_on_all_registries
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:maven/com.google/guava")
      .to_return(
        status: 200,
        body: [
          { "name" => "com.google:guava", "registry" => { "name" => "Maven Central" } },
          { "name" => "com.google:guava", "registry" => { "name" => "Google Maven" } }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries?ecosystem=maven")
      .to_return(
        status: 200,
        body: [
          { "name" => "Maven Central", "url" => "https://repo1.maven.org/maven2" },
          { "name" => "Google Maven", "url" => "https://maven.google.com" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @confusion.check("com.google:guava")

    refute result.confusion_risk?
  end

  def test_no_confusion_when_not_on_any_registry
    stub_request(:get, "https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg:maven/com.example/nonexistent")
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://packages.ecosyste.ms/api/v1/registries?ecosystem=maven")
      .to_return(
        status: 200,
        body: [
          { "name" => "Maven Central", "url" => "https://repo1.maven.org/maven2" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @confusion.check("com.example:nonexistent")

    refute result.confusion_risk?
    refute result.exists_anywhere
  end
end
