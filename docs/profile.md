# Supported Package URL profile

Moon PURL 0.2.1 implements an ASCII interoperability profile for Package URL.
This page is normative for the release; behavior outside it must not be inferred.

## Parsing and canonical output

The parser requires `pkg:type/path`, rejects empty structural segments, validates
percent triplets, and returns decoded fields. Canonical output lowercases the
scheme and type, emits uppercase ASCII percent triplets, sorts lowercase
qualifier keys, and rejects duplicate keys. Subpath segments `.` and `..` are
invalid. Error offsets are zero-based UTF-16 indices into the original string.

Known profiles add these checks:

| Type | 0.2.1 behavior |
| --- | --- |
| `pypi` | no namespace; name lowercased and runs of `-`, `_`, `.` collapsed to `-` |
| `npm` | optional single namespace beginning with `@`; scope/name lowercased |
| `maven` | namespace required |
| `golang` | namespace required |
| `github` | namespace required; owner and repository lowercased; version/tag casing preserved |
| other valid type | generic grammar only |

Literal non-ASCII characters and percent escapes above ASCII are preserved. The
library does not claim Unicode NFC, UTF-8 escape decoding, or equivalence across
different Unicode spellings in 0.2.1.

## SBOM adapter semantics

`import_cyclonedx_json` walks both top-level and nested `components`. It uses
`bom-ref`, then `name`, then a deterministic generated identifier, and emits an
imported, missing-PURL, or invalid-PURL finding for every component.

`import_spdx_json` walks `packages` and selects `externalRefs` whose category is
`PACKAGE-MANAGER` and type is `purl` or `package-url`. `SPDXID`, package name,
or a deterministic generated identifier becomes the record ID. The adapters
are extraction boundaries, not full schema validators.

## Identity and matching

`identity()` retains type, namespace, name, and version, while dropping
qualifiers and subpath. `same_package_version` and inventory duplicate detection
use that identity. This supports coarse joins with advisory databases, but it
does not assert equal binaries; callers should compare cryptographic digests for
that purpose.

`match_purl` treats omitted pattern fields as wildcards. Present fields match
exactly after parsing/profile normalization; required qualifiers are a subset.
The first mismatch becomes a stable `MatchResult` for CI output.

## Inventory semantics

Every input row produces one finding. Invalid syntax is isolated. The default
policy requires a version. A valid row can then be type-blocked, qualifier-
blocked, duplicate, or ready. `Ready` means only that the supplied PURL passes
the selected local checks; it is not a package availability or security claim.

`diff_inventory` compares unique normalized identities. Invalid rows are counted
separately, duplicate rows collapse, and all change lists are sorted so output is
independent of source ordering.
