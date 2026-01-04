## [Unreleased]

- Filter duplicate packages in SBOM checking to avoid redundant results and API calls

## [0.5.0] - 2026-01-04

- Add bulk lookup for SBOM checking to reduce API calls
- Test against Ruby 3.4 and 4.0 in CI

## [0.4.0] - 2026-01-02

- Skip intra-namespace typosquats for scoped packages (npm, composer, golang) since namespace owners control all packages under their namespace
- Add Dockerfile for running without Ruby installed

## [0.3.0] - 2025-12-17

- Add `discover` command to find existing similar packages by edit distance using prefix/postfix API

## [0.2.0] - 2025-12-17

- Add GitHub Actions ecosystem for CI/CD workflow typosquatting detection
- Add namespace-aware variant generation for ecosystems with owner/vendor (Go, Composer, npm scoped packages)
- Add bitflip algorithm for bitsquatting attacks
- Add adjacent_insertion algorithm for inserting adjacent keyboard characters
- Add double_hit algorithm for replacing consecutive identical characters with adjacent keys
- Add length-aware algorithm filtering to reduce false positives for short package names (under 5 chars)
- Add combosquatting algorithm for common package suffixes (-js, -py, -cli, -lite, etc.)

## [0.1.0] - 2025-12-16

- Initial release
