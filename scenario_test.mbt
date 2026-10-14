///|
/// Integration-scale scenario: a 1,200-row mixed-ecosystem inventory shaped
/// like an SBOM import. It verifies total accounting, duplicate joins, and
/// malformed-row isolation without relying on network services or clocks.
test "SBOM inventory scenario accounts for 1200 rows" {
  let rows : Array[@moon_purl.InventoryEntry] = []
  for i = 0; i < 1000; i = i + 1 {
    rows.push({
      record_id: "component-" + i.to_string(),
      purl: "pkg:pypi/package-" + i.to_string() + "@1.0.0",
    })
  }
  for i = 0; i < 100; i = i + 1 {
    rows.push({
      record_id: "duplicate-" + i.to_string(),
      purl: "pkg:pypi/package-" + i.to_string() + "@1.0.0#vendor",
    })
  }
  for i = 0; i < 50; i = i + 1 {
    rows.push({
      record_id: "invalid-" + i.to_string(),
      purl: "pkg:generic/bad%Q0-" + i.to_string() + "@1",
    })
  }
  for i = 0; i < 50; i = i + 1 {
    rows.push({
      record_id: "unversioned-" + i.to_string(),
      purl: "pkg:npm/tool-" + i.to_string(),
    })
  }
  let report = @moon_purl.audit_inventory(rows)
  assert_eq(report.findings.length(), 1200)
  assert_eq(report.ready, 1000)
  assert_eq(report.duplicate, 100)
  assert_eq(report.invalid, 50)
  assert_eq(report.unversioned, 50)
  assert_eq(report.policy_blocked, 0)
}
