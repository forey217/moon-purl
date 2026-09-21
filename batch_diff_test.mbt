///|
test "batch diagnostics preserve order and isolate failures" {
  let report = diagnose_batch([
    "pkg:pypi/Requests@2.32.3", "pkg:generic/bad%Q0@1", "pkg:npm/%40acme/widget@2",
  ])
  assert_eq(report.valid, 2)
  assert_eq(report.invalid, 1)
  assert_eq(report.findings.length(), 3)
  assert_eq(report.findings[0].index, 0)
  assert_eq(report.findings[0].canonical, "pkg:pypi/requests@2.32.3")
  assert_eq(report.findings[1].index, 1)
  assert_eq(report.findings[1].code, "BAD_PERCENT_ESCAPE")
  assert_eq(report.findings[2].index, 2)
}

///|
test "batch diagnostics report unsupported ecosystem profiles" {
  let report = diagnose_batch(["pkg:pypi/acme/widget@1", "pkg:maven/widget@1"])
  assert_eq(report.valid, 0)
  assert_eq(report.invalid, 2)
  assert_eq(report.findings[0].code, "PYPI_NAMESPACE")
  assert_eq(report.findings[1].code, "NAMESPACE_REQUIRED")
}

///|
test "inventory diff is canonical sorted and duplicate-insensitive" {
  let before = [
    InventoryEntry::{ record_id: "a", purl: "pkg:pypi/Flask@3.0.0", },
    InventoryEntry::{ record_id: "b", purl: "pkg:npm/lodash@4.17.20", },
    InventoryEntry::{ record_id: "b2", purl: "pkg:npm/lodash@4.17.20#vendor", },
    InventoryEntry::{ record_id: "bad", purl: "broken", },
  ]
  let after = [
    InventoryEntry::{ record_id: "a", purl: "pkg:pypi/flask@3.0.0?os=linux", },
    InventoryEntry::{ record_id: "b", purl: "pkg:npm/lodash@4.17.21", },
    InventoryEntry::{ record_id: "new", purl: "pkg:cargo/serde@1.0.210", },
  ]
  let delta = diff_inventory(before, after)
  assert_eq(delta.unchanged, ["pkg:pypi/flask@3.0.0"])
  assert_eq(delta.removed, ["pkg:npm/lodash@4.17.20"])
  assert_eq(delta.added, ["pkg:cargo/serde@1.0.210", "pkg:npm/lodash@4.17.21"])
  assert_eq(delta.invalid_before, 1)
  assert_eq(delta.invalid_after, 0)
}

///|
test "inventory diff treats empty snapshots explicitly" {
  let delta = diff_inventory([], [
    InventoryEntry::{ record_id: "new", purl: "pkg:generic/tool@1", },
  ])
  assert_eq(delta.added, ["pkg:generic/tool@1"])
  assert_eq(delta.removed, [])
  assert_eq(delta.unchanged, [])
}
