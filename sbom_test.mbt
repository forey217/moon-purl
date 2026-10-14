///|
test "CycloneDX import handles nested multi-ecosystem components" {
  let document =
    #|{
    #|  "bomFormat": "CycloneDX",
    #|  "components": [
    #|    {"bom-ref":"app", "name":"app", "purl":"pkg:npm/%40Acme/App@1.0.0", "components":[
    #|      {"bom-ref":"requests", "purl":"pkg:pypi/Requests@2.32.3"}
    #|    ]},
    #|    {"bom-ref":"lib", "purl":"pkg:maven/org.example/lib@2.0.0"},
    #|    {"bom-ref":"bad", "purl":"not-a-purl"},
    #|    {"bom-ref":"unknown"}
    #|  ]
    #|}
  let report = @moon_purl.import_cyclonedx_json(document)
  assert_eq(report.imported, 3)
  assert_eq(report.invalid, 1)
  assert_eq(report.missing, 1)
  assert_eq(report.entries[0].purl, "pkg:npm/%40acme/app@1.0.0")
  assert_eq(report.entries[1].purl, "pkg:pypi/requests@2.32.3")
  assert_eq(report.findings[3].code, "EXPECTED_PKG_SCHEME")
}

///|
test "SPDX package-manager references feed inventory policy" {
  let document =
    #|{
    #|  "spdxVersion":"SPDX-2.3",
    #|  "packages":[
    #|    {"SPDXID":"SPDXRef-A", "name":"A", "externalRefs":[
    #|      {"referenceCategory":"PACKAGE-MANAGER", "referenceType":"purl", "referenceLocator":"pkg:golang/github.com/acme/a@v1.2.0"}
    #|    ]},
    #|    {"SPDXID":"SPDXRef-B", "name":"B", "externalRefs":[
    #|      {"referenceCategory":"SECURITY", "referenceType":"cpe23Type", "referenceLocator":"cpe:2.3:a:acme:b:*:*:*:*:*:*:*:*"}
    #|    ]}
    #|  ]
    #|}
  let report = @moon_purl.audit_spdx_json(document)
  assert_eq(report.import_report.imported, 1)
  assert_eq(report.import_report.missing, 1)
  assert_eq(report.inventory_report.ready, 1)
  assert_eq(report.inventory_report.findings[0].record_id, "SPDXRef-A")
}

///|
test "malformed JSON documents fail with stable document errors" {
  let mut code = ""
  ignore(@moon_purl.import_cyclonedx_json("{broken")) catch {
    Syntax(found, _) => code = found
    _ => ()
  }
  assert_eq(code, "INVALID_JSON")
}

///|
test "CycloneDX and SPDX snapshots compare through canonical identities" {
  let before = @moon_purl.import_cyclonedx_json(
    (
      #|{"components":[
      #| {"bom-ref":"a", "purl":"pkg:pypi/Requests@2.32.3"},
      #| {"bom-ref":"b", "purl":"pkg:npm/lodash@4.17.21"}
      #|]}
    ),
  )
  let after = @moon_purl.import_spdx_json(
    (
      #|{"packages":[
      #| {"SPDXID":"A", "externalRefs":[{"referenceCategory":"PACKAGE-MANAGER","referenceType":"purl","referenceLocator":"pkg:pypi/requests@2.32.3"}]},
      #| {"SPDXID":"C", "externalRefs":[{"referenceCategory":"PACKAGE-MANAGER","referenceType":"purl","referenceLocator":"pkg:maven/org.example/core@1.0.0"}]}
      #|]}
    ),
  )
  let delta = @moon_purl.diff_sbom_imports(before, after)
  assert_eq(delta.unchanged, ["pkg:pypi/requests@2.32.3"])
  assert_eq(delta.removed, ["pkg:npm/lodash@4.17.21"])
  assert_eq(delta.added, ["pkg:maven/org.example/core@1.0.0"])
}
