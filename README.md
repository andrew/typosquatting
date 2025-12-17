# Typosquatting

Detect potential typosquatting packages across package ecosystems. Generate typosquat variants of package names and check if they exist on package registries.

Supports PyPI, npm, RubyGems, Cargo, Go, Maven, NuGet, Composer, Hex, Pub, and GitHub Actions.

## When to use this

**Typosquatting** is when an attacker publishes a malicious package with a name similar to a popular one, hoping developers mistype the name or copy-paste a bad example. This tool generates those similar names and checks if they exist.

**Dependency confusion** is when an attacker publishes a public package with the same name as your private/internal package, hoping your build system fetches the public one. The `confusion` command checks which registries have your package name.

This tool helps you:
- Find existing typosquats of packages you maintain
- Audit your dependencies for packages that look like typosquats of popular ones
- Check if your internal package names are safe from dependency confusion

False positives are common. A package named `request` isn't necessarily a typosquat of `requests`. Use the output as a starting point for investigation, not as a definitive verdict.

Short package names (under 5 characters) produce more false positives because many legitimate short packages exist. By default, the generator uses only high-confidence algorithms (homoglyph, repetition, replacement, transposition) for short names. Use `--no-length-filter` to disable this and run all algorithms regardless of name length.

## Installation

```bash
gem install typosquatting
```

Or add to your Gemfile:

```ruby
gem "typosquatting"
```

## CLI Usage

```bash
# Generate typosquat variants for a package
typosquatting generate requests -e pypi

# Use specific algorithms only
typosquatting generate requests -e pypi -a omission,homoglyph

# Show which algorithm generated each variant
typosquatting generate requests -e pypi -v

# Check which variants actually exist on registries
typosquatting check requests -e pypi

# Only show existing packages
typosquatting check requests -e pypi --existing-only

# Preview what would be checked without API calls
typosquatting check requests -e pypi --dry-run

# Check for dependency confusion risks
typosquatting confusion com.company:internal-lib -e maven

# Check GitHub Actions for typosquats
typosquatting check actions/checkout -e github_actions

# Check multiple packages from a file
typosquatting confusion -e maven --file internal-packages.txt

# Scan an SBOM for potential typosquats
typosquatting sbom bom.json

# Output as JSON
typosquatting check requests -e pypi -f json

# List available algorithms
typosquatting algorithms

# Discover existing packages similar to a target (by edit distance)
typosquatting discover requests -e pypi

# Discover with generated variants check
typosquatting discover requests -e pypi --with-variants
```

## Example Output

```bash
$ typosquatting check lodash -e npm --existing-only -v

Checking 142 variants...
lodas (omission) - EXISTS
  registries: npmjs.org
lodah (omission) - EXISTS
  registries: npmjs.org
1odash (homoglyph) - EXISTS
  registries: npmjs.org

Checked 142 variants, 3 exist
```

```bash
$ typosquatting sbom bom.json

Potential typosquats found:

reqests (pypi)
  Version: 1.0.0
  PURL: pkg:pypi/reqests@1.0.0
  Similar to existing packages:
    - requests (omission)
      registries: pypi.org

Found 1 suspicious package(s)
```

## Library Usage

```ruby
require "typosquatting"

# Generate variants (returns array of names)
variants = Typosquatting.generate("requests", ecosystem: "pypi")
# => ["reqests", "requets", "request", "reqeusts", ...]

# Generate with algorithm info
variants = Typosquatting.generate_with_algorithms("requests", ecosystem: "pypi")
variants.each do |v|
  puts "#{v.name} (#{v.algorithm})"
end

# Check which variants exist on registries
results = Typosquatting.check("requests", ecosystem: "pypi")
results.each do |result|
  puts "#{result.name} - #{result.exists? ? 'EXISTS' : 'available'}"
  puts "  registries: #{result.registries.map(&:name).join(', ')}" if result.exists?
end

# Dependency confusion check
confusion = Typosquatting.check_confusion("my-internal-package", ecosystem: "maven")
confusion.registries.each do |registry, exists|
  puts "#{registry}: #{exists ? 'EXISTS' : 'available'}"
end
puts "Risk detected!" if confusion.confusion_risk?

# Access ecosystem rules
ecosystem = Typosquatting::Ecosystem.get("pypi")
ecosystem.valid_name?("some-package")  # => true
ecosystem.normalise("Some_Package")    # => "some-package"

# Scan an SBOM
checker = Typosquatting::SBOMChecker.new("bom.json")
results = checker.check
results.each do |result|
  puts "#{result.name} may be a typosquat of:"
  result.suspicions.each do |s|
    puts "  - #{s.name} (#{s.algorithm})"
  end
end
```

## Supported Ecosystems

Use these identifiers with the `-e` / `--ecosystem` flag:

| ID | Registry | Case Sensitive | Delimiters | Notes |
|----|----------|----------------|------------|-------|
| `pypi` | PyPI | No | `-` `_` `.` | Normalizes to lowercase, collapses delimiters to `-` |
| `npm` | npmjs.org | No | `-` `_` `.` | Supports scoped packages (`@scope/name`) |
| `gem` | RubyGems | Yes | `-` `_` | No dots allowed |
| `cargo` | crates.io | No | `-` `_` | `_` and `-` are equivalent |
| `golang` | proxy.golang.org | Yes | `-` `_` `.` `/` | Module paths with `/`, version suffixes |
| `maven` | Maven Central | Yes | `-` `_` `.` | `groupId:artifactId` format |
| `nuget` | nuget.org | No | `-` `_` `.` | Dots common in names |
| `composer` | Packagist | No | `-` `_` `.` | `vendor/package` format |
| `hex` | hex.pm | No | `_` | Underscore only, no hyphens |
| `pub` | pub.dev | No | `_` | Underscore only, 2-64 chars |
| `github_actions` | GitHub | No | `-` `_` `.` | `owner/repo` format, targets CI/CD workflows |

## Algorithms

Use these names with the `-a` / `--algorithms` flag (comma-separated):

| Name | Description | Example |
|------|-------------|---------|
| `omission` | Drop single characters | `requests` -> `reqests` |
| `repetition` | Double characters | `requests` -> `rrequests` |
| `replacement` | Adjacent keyboard characters | `requests` -> `requezts` |
| `transposition` | Swap adjacent characters | `requests` -> `reqeusts` |
| `addition` | Insert characters at start/end | `requests` -> `arequests` |
| `homoglyph` | Lookalike characters | `requests` -> `reque5ts` |
| `vowel_swap` | Swap vowels | `requests` -> `raquests` |
| `delimiter` | Change/add/remove `-` `_` `.` | `my-package` -> `my_package` |
| `word_order` | Reorder words | `foo-bar` -> `bar-foo` |
| `plural` | Singularize/pluralize | `request` -> `requests` |
| `misspelling` | Common typos | `library` -> `libary` |
| `numeral` | Number/word swap | `lib2` -> `libtwo` |
| `bitflip` | Single-bit errors (bitsquatting) | `google` -> `coogle` |
| `adjacent_insertion` | Insert adjacent keyboard key | `google` -> `googhle` |
| `double_hit` | Replace double chars with adjacent | `google` -> `giigle` |
| `combosquatting` | Add common package suffixes | `lodash` -> `lodash-js` |

## SBOM Support

The `sbom` command parses CycloneDX and SPDX JSON files. It reads the `purl` field from each component to determine the ecosystem and package name.

Supported formats:
- CycloneDX 1.4+ (JSON)
- SPDX 2.2+ (JSON)

The checker looks for packages in your SBOM that have names similar to existing popular packages, which could indicate you've installed a typosquat.

## API and Rate Limiting

Package lookups use the [ecosyste.ms](https://packages.ecosyste.ms) API. Requests are made in parallel (10 concurrent by default) to improve performance.

Be mindful when checking many packages. The `--dry-run` flag shows what would be checked without making API calls.

### packages.ecosyste.ms API

The package_names endpoint can help identify potential typosquats by searching for packages with similar prefixes or postfixes to popular package names.

```
GET /api/v1/registries/{registry}/package_names
```

**Parameters:**
- `prefix` - filter by package names starting with string (case insensitive)
- `postfix` - filter by package names ending with string (case insensitive)
- `page`, `per_page` - pagination
- `sort`, `order` - sorting

**Examples:**
```
# Find RubyGems packages ending in "ails" (potential "rails" typosquats)
https://packages.ecosyste.ms/api/v1/registries/rubygems.org/package_names?postfix=ails

# Find RubyGems packages starting with "rai" (potential "rails" typosquats)
https://packages.ecosyste.ms/api/v1/registries/rubygems.org/package_names?prefix=rai

# Find npm packages starting with "reac" (potential "react" typosquats)
https://packages.ecosyste.ms/api/v1/registries/npmjs.org/package_names?prefix=reac
```

Full API documentation: [packages.ecosyste.ms/docs](https://packages.ecosyste.ms/docs)

## Dataset

The [ecosyste-ms/typosquatting-dataset](https://github.com/ecosyste-ms/typosquatting-dataset) contains 143 confirmed typosquatting attacks from security research, mapping malicious packages to their targets with classification and source attribution. Useful for testing detection tools and understanding real attack patterns.

## Development

```bash
git clone https://github.com/andrew/typosquatting
cd typosquatting
bundle install
bundle exec rake test
```

Run locally without installing:

```bash
bundle exec ruby -Ilib exe/typosquatting help
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/andrew/typosquatting.

## License

MIT
