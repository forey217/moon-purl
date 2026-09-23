///|
/// Reproducible downstream integration: import a CycloneDX JSON document and
/// run canonical package inventory policy in one operation.
fn main raise {
  let document =
    #|{
    #| "bomFormat":"CycloneDX",
    #| "components":[
    #|  {"bom-ref":"frontend", "purl":"pkg:npm/%40Acme/Widget@2.1.0"},
    #|  {"bom-ref":"backend", "purl":"pkg:PyPI/Requests@2.32.3"},
    #|  {"bom-ref":"duplicate", "purl":"pkg:pypi/requests@2.32.3#vendor"},
    #|  {"bom-ref":"broken", "purl":"pkg:generic/bad%Q0@1"},
    #|  {"bom-ref":"undocumented"}
    #| ]
    #|}
  let result = @lib.audit_cyclonedx_json(document)
  let imported = result.import_report
  let report = result.inventory_report
  println(
    "CycloneDX import: imported=\{imported.imported} invalid=\{imported.invalid} missing=\{imported.missing}",
  )
  println(
    "ready=\{report.ready} invalid=\{report.invalid} unversioned=\{report.unversioned} duplicate=\{report.duplicate} blocked=\{report.policy_blocked}",
  )
  for finding in imported.findings {
    println("\{finding.record_id}: \{finding.code} \{finding.canonical}")
  }
}
