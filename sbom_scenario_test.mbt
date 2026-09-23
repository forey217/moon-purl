///|
/// Integration-scale JSON ingestion: the parser must account for every
/// component while isolating malformed and missing PURLs.
test "CycloneDX JSON scenario imports and audits 1500 components" {
  let output = StringBuilder()
  output.write_string("{\"bomFormat\":\"CycloneDX\",\"components\":[")
  for i = 0; i < 1500; i = i + 1 {
    if i > 0 {
      output.write_char(',')
    }
    if i < 1200 {
      output.write_string(
        "{\"bom-ref\":\"ok-" +
        i.to_string() +
        "\",\"purl\":\"pkg:pypi/package-" +
        i.to_string() +
        "@1.0.0\"}",
      )
    } else if i < 1300 {
      output.write_string(
        "{\"bom-ref\":\"duplicate-" +
        i.to_string() +
        "\",\"purl\":\"pkg:pypi/package-" +
        (i - 1200).to_string() +
        "@1.0.0#vendor\"}",
      )
    } else if i < 1400 {
      output.write_string(
        "{\"bom-ref\":\"bad-" +
        i.to_string() +
        "\",\"purl\":\"pkg:generic/bad%Q0@1\"}",
      )
    } else {
      output.write_string("{\"bom-ref\":\"missing-" + i.to_string() + "\"}")
    }
  }
  output.write_string("]}")
  let result = audit_cyclonedx_json(output.to_string())
  assert_eq(result.import_report.findings.length(), 1500)
  assert_eq(result.import_report.imported, 1300)
  assert_eq(result.import_report.invalid, 100)
  assert_eq(result.import_report.missing, 100)
  assert_eq(result.inventory_report.ready, 1200)
  assert_eq(result.inventory_report.duplicate, 100)
}
