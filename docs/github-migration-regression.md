# GitHub casing-only migration regression

Version 0.2.1 fixes a package-identity false positive in `diff_sbom_imports`.
A CycloneDX component containing `pkg:github/AcMe/Supply-Chain@v1.2.3` and an
SPDX package referencing `pkg:github/acme/supply-chain@v1.2.3` describe the same
repository/version. Version 0.2.0 preserved the owner/repository casing, so its
identity comparison incorrectly reported one added and one removed component.

The [official GitHub PURL definition](https://github.com/package-url/purl-spec/blob/main/docs/types/definitions/github-definition.md)
requires lowercase owner and repository fields. The parser now applies that
rule before imported entries, canonical strings, inventory identities or
migration differences are produced. Version/tag spelling remains unchanged;
the fix does not case-fold every PURL type.

The public API regression in `github_migration_test.mbt` imports both JSON
formats and checks the comparison in both directions. Expected results:

```text
added: []
removed: []
unchanged: ["pkg:github/acme/supply-chain@v1.2.3"]
invalid_before: 0
invalid_after: 0
```

Six additional test blocks cover canonicalization/idempotence, the cross-format
migration, inventory deduplication, genuine owner/repository changes, changed
versions and tag casing, and case-sensitive generic/Maven/Go package types.
All fixtures are synthetic and contain no account or repository credentials.

On 2026-10-14, the new tests produced five failures against the old GitHub
normalization logic. After the parser correction, all 27 project tests passed
locally on JavaScript, Wasm and WasmGC with `--deny-warn`. The original
20,000-row inventory and 5,000-component workload retained their expected counts.
The four-target CI includes the native backend; consult the actual Actions run
for its result.

```sh
moon fmt --check
moon check --target js --deny-warn
moon test --target js --deny-warn
moon test --target wasm --deny-warn
moon test --target wasm-gc --deny-warn
moon run cmd/benchmark --target js
```

The compiler and core are pinned together at `0.10.15+943464bfa` in CI. Explicit
Eq/Debug method exposure preserves the methods previously provided implicitly;
blackbox tests now use explicit package aliases required by that compiler.
The existing ASCII interoperability profile and SBOM extraction boundaries
continue to apply. This correction does not claim full PURL Unicode support or
full CycloneDX/SPDX validation.
