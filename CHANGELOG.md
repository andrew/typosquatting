## [Unreleased]

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
