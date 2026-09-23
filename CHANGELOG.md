# Changelog

## 0.2.0 - 2026-09-23

- Import top-level and nested CycloneDX JSON components.
- Import SPDX package-manager PURL external references.
- Audit imported documents without aborting on malformed or missing PURLs.
- Compare canonical package identities across SBOM formats.
- Add a 1,500-component integration test and 5,000-component JSON workload.

## 0.1.0 - 2026-09-21

- Parse and canonicalize the documented Package URL interoperability profile.
- Match structured package fields and qualifier subsets.
- Diagnose batches without aborting after malformed rows.
- Audit inventories for invalid, unversioned, duplicate, and blocked records.
- Diff normalized identities across inventory snapshots.
- Add four-target CI, deterministic scenarios, and a 20,000-row workload.
