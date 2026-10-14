///|
test "GitHub owner and repository canonicalize without changing the tag" {
  let value = @moon_purl.parse("pkg:GITHUB/AcMe/Supply-Chain@Release-V1")
  assert_eq(value.namespace_parts, ["acme"])
  assert_eq(value.name, "supply-chain")
  assert_eq(value.version, Some("Release-V1"))
  assert_eq(value.to_string(), "pkg:github/acme/supply-chain@Release-V1")
  assert_eq(@moon_purl.parse(value.to_string()).to_string(), value.to_string())
  assert_true(
    @moon_purl.same_package_version(
      value,
      @moon_purl.parse("pkg:github/ACME/SUPPLY-CHAIN@Release-V1"),
    ),
  )
}

///|
test "GitHub casing-only CycloneDX to SPDX migration has no identity changes" {
  let before = @moon_purl.import_cyclonedx_json(
    (
      #|{"bomFormat":"CycloneDX","components":[
      #|  {"bom-ref":"original-ref","purl":"pkg:github/AcMe/Supply-Chain@v1.2.3"}
      #|]}
    ),
  )
  let after = @moon_purl.import_spdx_json(
    (
      #|{"spdxVersion":"SPDX-2.3","packages":[
      #|  {"SPDXID":"SPDXRef-New","externalRefs":[
      #|    {"referenceCategory":"PACKAGE-MANAGER","referenceType":"purl","referenceLocator":"pkg:github/acme/supply-chain@v1.2.3"}
      #|  ]}
      #|]}
    ),
  )
  assert_eq(before.imported, 1)
  assert_eq(after.imported, 1)
  for
    delta in [
      @moon_purl.diff_sbom_imports(before, after),
      @moon_purl.diff_sbom_imports(after, before),
    ] {
    assert_eq(delta.added, [])
    assert_eq(delta.removed, [])
    assert_eq(delta.unchanged, ["pkg:github/acme/supply-chain@v1.2.3"])
    assert_eq(delta.invalid_before, 0)
    assert_eq(delta.invalid_after, 0)
  }
  assert_eq(before.entries[0].purl, after.entries[0].purl)
}

///|
test "GitHub canonical identity still reports changed versions and tag case" {
  let before : Array[@moon_purl.InventoryEntry] = [
    { record_id: "before", purl: "pkg:github/AcMe/Library@Release-V1", },
  ]
  for version in ["Release-V2", "release-v1"] {
    let after : Array[@moon_purl.InventoryEntry] = [
      { record_id: "after", purl: "pkg:github/acme/library@" + version, },
    ]
    let delta = @moon_purl.diff_inventory(before, after)
    assert_eq(delta.unchanged, [])
    assert_eq(delta.removed, ["pkg:github/acme/library@Release-V1"])
    assert_eq(delta.added, ["pkg:github/acme/library@" + version])
  }
}

///|
test "GitHub repository and owner changes remain distinct" {
  let before : Array[@moon_purl.InventoryEntry] = [
    { record_id: "before", purl: "pkg:github/AcMe/Library@v1", },
  ]
  for purl in ["pkg:github/acme/other@v1", "pkg:github/other/library@v1"] {
    let delta = @moon_purl.diff_inventory(before, [
      { record_id: "after", purl, },
    ])
    assert_eq(delta.unchanged, [])
    assert_eq(delta.removed, ["pkg:github/acme/library@v1"])
    assert_eq(delta.added, [purl])
  }
}

///|
test "GitHub casing variants deduplicate in the public inventory API" {
  let report = @moon_purl.audit_inventory([
    { record_id: "a", purl: "pkg:github/AcMe/Library@v1", },
    { record_id: "b", purl: "pkg:github/acme/LIBRARY@v1", },
  ])
  assert_eq(report.ready, 1)
  assert_eq(report.duplicate, 1)
  assert_eq(report.findings[1].decision, Duplicate)
  assert_eq(report.findings[0].canonical, report.findings[1].canonical)
}

///|
test "GitHub folding does not change case-sensitive package types" {
  for package_type in ["generic", "maven", "golang"] {
    let before : Array[@moon_purl.InventoryEntry] = [
      { record_id: "before", purl: "pkg:" + package_type + "/AcMe/Library@v1", },
    ]
    let after : Array[@moon_purl.InventoryEntry] = [
      { record_id: "after", purl: "pkg:" + package_type + "/acme/library@v1", },
    ]
    let delta = @moon_purl.diff_inventory(before, after)
    assert_eq(delta.unchanged, [])
    assert_eq(delta.added.length(), 1)
    assert_eq(delta.removed.length(), 1)
  }
}
