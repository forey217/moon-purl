# Source and provenance statement

Moon PURL is an independent MoonBit implementation written for this project.
Its public behavior references the open [Package URL specification](https://github.com/package-url/purl-spec)
and the packaging conventions named in `docs/profile.md`. No third-party parser
source or test suite was copied or translated into this repository.

The project uses only `moonbitlang/core` at runtime, including its JSON parser,
and is released under Apache-2.0. CycloneDX and SPDX adapters were independently
implemented from the public document field conventions; no third-party SBOM
parser source was copied. Examples and generated scenario rows are authored for this repository.
Names such as Requests, lodash, and Maven coordinates are interoperability
examples; they are not bundled third-party software or claims about those
packages.

The contribution history must remain attributable to the GitHub owner. Tokens,
cookies, local paths, and unpublished credentials must never be committed.
