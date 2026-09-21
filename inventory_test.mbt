///|
test "inventory audit classifies every row" {
  let report = audit_inventory(
    [
      { record_id: "a", purl: "pkg:pypi/Requests@2.32.3", },
      { record_id: "b", purl: "pkg:pypi/requests@2.32.3#src", },
      { record_id: "c", purl: "pkg:npm/lodash", },
      { record_id: "d", purl: "not-a-purl", },
      { record_id: "e", purl: "pkg:generic/acme/tool@1", },
    ],
    policy={
      require_version: true,
      blocked_types: ["generic"],
      required_qualifiers: [],
    },
  )
  assert_eq(report.ready, 1)
  assert_eq(report.duplicate, 1)
  assert_eq(report.unversioned, 1)
  assert_eq(report.invalid, 1)
  assert_eq(report.policy_blocked, 1)
  assert_eq(report.findings.length(), 5)
  assert_eq(report.findings[1].decision, Duplicate)
  assert_eq(report.findings[3].code, "EXPECTED_PKG_SCHEME")
}

///|
test "required qualifier policy checks key and value" {
  let report = audit_inventory(
    [
      {
        record_id: "ok",
        purl: "pkg:generic/tool@1?download_url=https:%2F%2Fexample",
      },
      { record_id: "missing", purl: "pkg:generic/tool@2", },
      {
        record_id: "wrong",
        purl: "pkg:generic/tool@3?download_url=https:%2F%2Fmirror",
      },
    ],
    policy={
      require_version: true,
      blocked_types: [],
      required_qualifiers: [{ key: "download_url", value: "https://example", }],
    },
  )
  assert_eq(report.ready, 1)
  assert_eq(report.policy_blocked, 2)
  assert_eq(report.findings[1].code, "QUALIFIER_REQUIRED:download_url")
}
