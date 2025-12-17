# Typosquatting Research Tools

Scripts for analyzing potential typosquats across package registries.

## critical_packages.rb

Scans critical packages (high OpenSSF criticality score) from a registry for potential typosquats using our detection algorithms. Results are written to a timestamped CSV file.

```bash
# Scan rubygems.org critical packages (high-confidence algorithms only)
ruby research/critical_packages.rb rubygems.org

# Include all algorithm matches
ruby research/critical_packages.rb rubygems.org --all

# Limit to first N packages (useful for testing)
ruby research/critical_packages.rb rubygems.org --limit=100
```

Supported registries: rubygems.org, npmjs.org, pypi.org, crates.io, packagist.org, hex.pm, pub.dev, proxy.golang.org, repo1.maven.org, nuget.org

## Algorithms

By default, only high-confidence algorithms are used (less likely to produce false positives):

- homoglyph - lookalike characters (l vs 1, O vs 0)
- repetition - doubled characters (lodash vs llodash)
- replacement - adjacent keyboard keys (lodash vs lodazh)
- transposition - swapped adjacent characters (lodash vs lodasj)
- omission - dropped characters (lodash vs lodas)

Use `--all` to include all 17 algorithms.

## Filters

The script applies several filters to reduce false positives:

- **Short names**: Packages under 5 characters are skipped (too many false positives)
- **Higher downloads**: Packages with more downloads than the critical package are skipped (not typosquats)
- **Popular packages**: Packages with >= 1% of the critical package's downloads are skipped (likely legitimate)
- **Predates target**: Packages created before the critical package are skipped (can't be typosquats)

## CSV Output

Output files are named `{registry}_{timestamp}.csv` with these columns:

| Column | Description |
|--------|-------------|
| critical_package | The critical package being checked |
| critical_downloads | Total downloads of the critical package |
| critical_created | First release date of the critical package |
| critical_repo | Repository URL of the critical package |
| potential_typosquat | A similarly named package that exists |
| algorithm | Which detection algorithm matched |
| squat_downloads | Total downloads of the potential typosquat |
| download_ratio | Squat downloads as percentage of critical downloads |
| squat_created | First release date of the potential typosquat |
| squat_status | Package status (empty = active, "removed" = yanked) |
| squat_repo | Repository URL of the potential typosquat |
| squat_description | Package description |

## Interpreting Results

Signs of a real typosquat:
- `squat_status` is "removed" (already yanked by registry)
- No repository URL
- Very low download ratio
- Description is empty or generic
- Created shortly after the critical package became popular

Signs of a false positive:
- Has a legitimate repository with real code
- Description describes unrelated functionality
- Reasonable download count for its purpose
