# frozen_string_literal: true

require_relative "lib/typosquatting/version"

Gem::Specification.new do |spec|
  spec.name = "typosquatting"
  spec.version = Typosquatting::VERSION
  spec.authors = ["Andrew Nesbitt"]
  spec.email = ["andrewnez@gmail.com"]

  spec.summary = "Detect potential typosquatting packages across package ecosystems"
  spec.description = "Generate typosquat variants of package names and check if they exist on package registries. Supports PyPI, npm, RubyGems, Cargo, Go, Maven, NuGet, Composer, Hex, and Pub."
  spec.homepage = "https://github.com/andrew/typosquatting"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/andrew/typosquatting"
  spec.metadata["changelog_uri"] = "https://github.com/andrew/typosquatting/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore test/ .github/])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sbom", "~> 0.2"
  spec.add_dependency "purl", "~> 1.6"
end
