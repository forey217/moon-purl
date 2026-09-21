///|
/// Deterministic 20,000-row workload used by docs/scenario-validation.md.
/// Timing is measured by the host so this program stays portable on all four
/// MoonBit targets.
fn main {
  let rows : Array[@lib.InventoryEntry] = []
  for i = 0; i < 16000; i = i + 1 {
    rows.push({
      record_id: "component-" + i.to_string(),
      purl: "pkg:pypi/package-" + i.to_string() + "@1.0.0",
    })
  }
  for i = 0; i < 2000; i = i + 1 {
    rows.push({
      record_id: "duplicate-" + i.to_string(),
      purl: "pkg:pypi/package-" + i.to_string() + "@1.0.0#vendor",
    })
  }
  for i = 0; i < 1000; i = i + 1 {
    rows.push({
      record_id: "invalid-" + i.to_string(),
      purl: "pkg:generic/bad%Q0-" + i.to_string() + "@1",
    })
  }
  for i = 0; i < 1000; i = i + 1 {
    rows.push({
      record_id: "unversioned-" + i.to_string(),
      purl: "pkg:npm/tool-" + i.to_string(),
    })
  }
  let report = @lib.audit_inventory(rows)
  println(
    "rows=\{report.findings.length()} ready=\{report.ready} duplicate=\{report.duplicate} invalid=\{report.invalid} unversioned=\{report.unversioned} blocked=\{report.policy_blocked}",
  )
}
