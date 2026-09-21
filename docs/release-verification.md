# MoonCakes 0.1.0 release verification

## Publication

- Module: `forey217/moon_purl`
- Version: `0.1.0`
- Published: 2026-09-21
- Server response: `200 OK`
- Git source commit used for the package: `450f6572f01b2c880361eaaf67ed2bb66f05593a`

Before publication, `moon publish --dry-run --frozen` rebuilt and checked the
extracted archive and returned `202 Accepted` for the same owner/module/version.
The formal `moon publish --frozen` repeated both checks before the server accepted
the release.

## Independent consumer check

A fresh project outside the source tree was created on drive D and installed the
exact registry version:

```powershell
moon add forey217/moon_purl@0.1.0
moon test --target js --deny-warn
```

The consumer imported `forey217/moon_purl`, canonicalized
`pkg:PyPI/Requests@2.32.3`, and audited two records whose normalized identities
collide. The independent result was `1 passed, 0 failed`.

## Archive identity

The archive generated at publication and the archive fetched into a clean
consumer registry cache have the same SHA-256:

```text
0B2274468DA6D61468903946F5EE4365828ED43E5984D22385DC22A75F3C0A03
```

This proves the checked archive and fetched 0.1.0 archive are byte-identical. It
does not make any claim about future versions.
