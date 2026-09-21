# SBOM inventory scenario and performance record

## Purpose

The scenario models an offline SBOM ingestion boundary: mixed package ecosystems,
canonical spelling differences, duplicate package-version identities, missing
versions, and malformed percent escapes. It validates local normalization and
classification only; the data is generated and does not claim to be a production
SBOM corpus.

## Reliability test

`scenario_test.mbt` creates 1,200 rows: 1,000 unique versioned PyPI packages,
100 duplicates distinguished only by subpath, 50 malformed PURLs, and 50
unversioned npm packages. The test asserts that all 1,200 rows receive findings:

| Decision | Expected |
| --- | ---: |
| ready | 1,000 |
| duplicate | 100 |
| invalid | 50 |
| unversioned | 50 |
| policy-blocked | 0 |

Reproduce with:

```powershell
moon test --target js --deny-warn
```

The full suite contains 16 test blocks and passes on wasm, wasm-gc, and
JavaScript locally. Native is verified by CI because this Windows host does not
have a C compiler installed.

## Performance workload

`cmd/benchmark` deterministically generates 20,000 rows: 16,000 unique records,
2,000 duplicates, 1,000 malformed records, and 1,000 unversioned records. The
expected line is:

```text
rows=20000 ready=16000 duplicate=2000 invalid=1000 unversioned=1000 blocked=0
```

On 2026-09-21, after a warm build, five complete `moon run cmd/benchmark
--target js` invocations took **167.3, 176.2, 169.5, 161.0, and 171.5 ms**
(median 169.5 ms). This includes Moon command and Node process startup, input
generation, parsing, canonicalization, identity hashing, and reporting.

Environment: Windows 11 10.0.26100 (64-bit), Intel Core i7-14650HX, Node.js
24.13.1, Moon 0.1.20260904, and MoonBit compiler 0.10.12+1634b282e. Results are
a reproducible local baseline, not a cross-machine performance guarantee.

## Acceptance boundary

The scenario passes when counts match exactly, no malformed row aborts a later
row, duplicate classification uses canonical identity, and repeated output is
stable. It does not validate CycloneDX/SPDX file parsing, remote package existence,
vulnerability status, digest equality, or dependency resolution.
