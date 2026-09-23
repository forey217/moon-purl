///|
/// Deterministic inventory and real SBOM JSON workloads.
/// Timing is measured by the host so this program stays portable on all four
/// MoonBit targets.
fn main raise {
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
  let json = StringBuilder()
  json.write_string("{\"bomFormat\":\"CycloneDX\",\"components\":[")
  for i = 0; i < 5000; i = i + 1 {
    if i > 0 {
      json.write_char(',')
    }
    if i < 4000 {
      json.write_string(
        "{\"bom-ref\":\"ok-" +
        i.to_string() +
        "\",\"purl\":\"pkg:npm/tool-" +
        i.to_string() +
        "@1.0.0\"}",
      )
    } else if i < 4500 {
      json.write_string(
        "{\"bom-ref\":\"dup-" +
        i.to_string() +
        "\",\"purl\":\"pkg:npm/tool-" +
        (i - 4000).to_string() +
        "@1.0.0#vendor\"}",
      )
    } else if i < 4750 {
      json.write_string(
        "{\"bom-ref\":\"bad-" + i.to_string() + "\",\"purl\":\"not-a-purl\"}",
      )
    } else {
      json.write_string("{\"bom-ref\":\"missing-" + i.to_string() + "\"}")
    }
  }
  json.write_string("]}")
  let sbom = @lib.audit_cyclonedx_json(json.to_string())
  println(
    "cyclonedx=\{sbom.import_report.findings.length()} imported=\{sbom.import_report.imported} missing=\{sbom.import_report.missing} invalid-purl=\{sbom.import_report.invalid} ready=\{sbom.inventory_report.ready} duplicate=\{sbom.inventory_report.duplicate}",
  )
}
