# SBOM inventory scenario and performance record

## Purpose

The scenarios model an offline SBOM ingestion boundary: actual CycloneDX/SPDX
JSON structure, nested components, mixed ecosystems, canonical spelling
differences, duplicate identities, missing PURLs, and malformed PURLs. Data is
generated and does not claim to be a production corpus.

## Reliability test

`scenario_test.mbt` creates 1,200 inventory rows: 1,000 unique versioned PyPI packages,
100 duplicates distinguished only by subpath, 50 malformed PURLs, and 50
unversioned npm packages. The test asserts that all 1,200 rows receive findings:

| Decision | Expected |
| --- | ---: |
| ready | 1,000 |
| duplicate | 100 |
| invalid | 50 |
| unversioned | 50 |
| policy-blocked | 0 |

`sbom_scenario_test.mbt` builds and parses a CycloneDX JSON document containing
1,500 components. Expected import results are 1,300 imported, 100 invalid PURLs,
and 100 missing PURLs. The 1,300 imported records then produce 1,200 ready and
100 duplicate inventory results. `sbom_test.mbt` additionally verifies nested
CycloneDX components, SPDX package-manager external references, stable malformed
document errors, and a CycloneDX-to-SPDX identity diff.

Reproduce with:

```powershell
moon test --target js --deny-warn
```

The full suite contains 21 test blocks and passes on wasm, wasm-gc, and
JavaScript locally. Native is verified by CI because this Windows host does not
have a C compiler installed.

## Performance workload

`cmd/benchmark` first audits 20,000 normalized rows, then generates, parses, and
audits a real 5,000-component CycloneDX JSON document. The expected lines are:

```text
rows=20000 ready=16000 duplicate=2000 invalid=1000 unversioned=1000 blocked=0
cyclonedx=5000 imported=4500 missing=250 invalid-purl=250 ready=4000 duplicate=500
```

On 2026-09-23, after a warm build, five complete `moon run cmd/benchmark
--target js` invocations took **201.6, 205.2, 194.1, 195.3, and 203.1 ms**
(median 201.6 ms). This includes Moon command and Node process startup, JSON
generation/parsing, PURL canonicalization, identity hashing, and reporting.

Environment: Windows 11 10.0.26100 (64-bit), Intel Core i7-14650HX, Node.js
24.13.1, Moon 0.1.20260904, and MoonBit compiler 0.10.12+1634b282e. Results are
a reproducible local baseline, not a cross-machine performance guarantee.

## Acceptance boundary

The scenario passes when all document items are accounted for, a malformed or
missing PURL does not abort siblings, duplicate classification uses canonical
identity, and cross-format results are stable. The adapter extracts the subset
needed for package identity work; it does not claim full schema validation,
remote package existence, vulnerability status, digest equality, or dependency
resolution.
