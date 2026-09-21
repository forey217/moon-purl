///|
/// Reproducible SBOM-ingest demonstration. The rows model dependencies from
/// several ecosystems and intentionally include a duplicate and invalid PURL.
fn main {
  let rows = [
    @lib.InventoryEntry::{
      record_id: "frontend-001",
      purl: "pkg:npm/%40acme/widget@2.1.0?os=linux",
    },
    @lib.InventoryEntry::{
      record_id: "backend-001",
      purl: "pkg:PyPI/Requests@2.32.3",
    },
    @lib.InventoryEntry::{
      record_id: "backend-002",
      purl: "pkg:pypi/requests@2.32.3#vendor",
    },
    @lib.InventoryEntry::{
      record_id: "service-001",
      purl: "pkg:maven/org.example/service@1.4.0?type=jar",
    },
    @lib.InventoryEntry::{
      record_id: "broken-001",
      purl: "pkg:generic/bad%Q0@1",
    },
  ]
  let report = @lib.audit_inventory(rows)
  println("Moon PURL SBOM audit: \{report.findings.length()} rows")
  println(
    "ready=\{report.ready} invalid=\{report.invalid} unversioned=\{report.unversioned} duplicate=\{report.duplicate} blocked=\{report.policy_blocked}",
  )
  for finding in report.findings {
    println(
      "\{finding.record_id}: \{finding.decision.to_string()} \{finding.canonical} \{finding.code}",
    )
  }
}
