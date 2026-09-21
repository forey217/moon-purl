# Moon PURL

[![CI](https://github.com/forey217/moon-purl/actions/workflows/ci.yml/badge.svg)](https://github.com/forey217/moon-purl/actions/workflows/ci.yml)

Moon PURL is a pure MoonBit library for parsing, canonicalizing, matching, and
auditing [Package URLs](https://github.com/package-url/purl-spec). It targets
SBOM import, vulnerability-database joins, dependency inventory validation, and
repeatable CI diagnostics.

The first release deliberately implements a documented **ASCII interoperability
profile** rather than claiming every Unicode rule in the full PURL specification.
It accepts generic types and adds conservative checks for PyPI, npm, Maven, Go,
and GitHub coordinates.

## What it does

- parses PURLs into typed fields with stable error codes and UTF-16 offsets;
- canonicalizes scheme/type, percent escapes, PyPI names, npm names/scopes, and
  sorted qualifier keys;
- matches explicit type/namespace/name/version fields and qualifier subsets;
- creates a package-version identity suitable for joins and duplicate warnings;
- isolates malformed rows in batch diagnostics;
- audits inventories for invalid, unversioned, duplicate, and policy-blocked rows;
- compares two inventories and reports added, removed, and unchanged identities;
- ships a runnable SBOM scenario, a 20,000-row workload, and four-target CI.

## Quick start

```moonbit nocheck
///|
test {
  let value = @moon_purl.parse(
    "pkg:npm/%40Acme/Widget@2.1.0?os=linux&arch=arm64",
  )
  assert_eq(
    value.to_string(),
    "pkg:npm/%40acme/widget@2.1.0?arch=arm64&os=linux",
  )
  assert_eq(value.identity(), "pkg:npm/%40acme/widget@2.1.0")
}
```

After the package is available from MoonCakes:

```powershell
moon add forey217/moon_purl
```

Run the checked-in scenario and workload from this repository:

```powershell
moon run cmd/main --target js
moon run cmd/benchmark --target js
```

The scenario reports one malformed row without aborting the remaining SBOM
records. The workload has a fixed expected result:

```text
rows=20000 ready=16000 duplicate=2000 invalid=1000 unversioned=1000 blocked=0
```

## Inventory audit

```moonbit nocheck
let report = @moon_purl.audit_inventory(
  [
    { record_id: "a", purl: "pkg:pypi/Requests@2.32.3" },
    { record_id: "b", purl: "pkg:pypi/requests@2.32.3#vendor" },
    { record_id: "c", purl: "pkg:npm/lodash" },
  ],
)

assert_eq(report.ready, 1)
assert_eq(report.duplicate, 1)
assert_eq(report.unversioned, 1)
```

`Duplicate` compares normalized type, namespace, name, and version. Qualifiers
and subpath are intentionally ignored, so it is a join warning—not proof that
two artifacts are byte-identical. Use hashes when byte identity matters.

## Validation

```powershell
moon fmt --check
moon check --target js --deny-warn
moon test --target js --deny-warn
```

There are 16 deterministic test blocks, including a 1,200-row integration
scenario. GitHub Actions checks wasm, wasm-gc, JavaScript, and native targets.
See [scenario validation](docs/scenario-validation.md) for commands, expected
counts, timings, environment, and interpretation.

## Explicit boundaries

- No network access, registry lookup, vulnerability query, or SBOM file parser.
- No claim of full Unicode normalization; non-ASCII text is preserved under the
  documented profile rather than silently rewritten.
- No claim that matching identities imply the same artifact bytes.
- No dependency resolution, license decision, or security verdict.
- PURL profile rules beyond the named ecosystems use the generic grammar.

See [profile design](docs/profile.md), [source statement](docs/provenance.md),
and the [project proposal](docs/proposal.md).

## License

Apache-2.0.
