// Learn more about moon.mod configuration:
// https://docs.moonbitlang.com/en/latest/toolchain/moon/module.html
//
// To add a dependency, run this command in your terminal:
//   moon add moonbitlang/x
//
// Or manually declare it in `import`, for example:
// import {
//   "moonbitlang/x@0.4.6",
// }

name = "forey217/moon_purl"

version = "0.1.0"

readme = "README.mbt.md"

repository = "https://github.com/forey217/moon-purl"

license = "Apache-2.0"

keywords = [ "package-url", "purl", "sbom", "supply-chain" ]

preferred_target = "wasm"

description = "Parse, canonicalize, match, and audit Package URLs for MoonBit supply-chain tooling"
