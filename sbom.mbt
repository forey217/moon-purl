///|
fn json_string_field(object : Map[String, Json], key : String) -> String? {
  match object.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn sbom_finding(
  record_id : String,
  decision : SbomImportDecision,
  input : String,
  canonical : String,
  code : String,
  offset : Int32,
) -> SbomImportFinding {
  { record_id, decision, input, canonical, code, offset, }
}

///|
fn import_one_purl(
  record_id : String,
  raw : String?,
  entries : Array[InventoryEntry],
  findings : Array[SbomImportFinding],
) -> Unit {
  match raw {
    None =>
      findings.push(
        sbom_finding(record_id, MissingPurl, "", "", "PURL_MISSING", -1),
      )
    Some(input) => {
      let value = parse(input) catch {
        Syntax(code, offset) => {
          findings.push(
            sbom_finding(record_id, InvalidPurl, input, "", code, offset),
          )
          return
        }
        Unsupported(code, offset) => {
          findings.push(
            sbom_finding(record_id, InvalidPurl, input, "", code, offset),
          )
          return
        }
      }
      let canonical = value.to_string()
      entries.push({ record_id, purl: canonical, })
      findings.push(sbom_finding(record_id, Imported, input, canonical, "", -1))
    }
  }
}

///|
fn collect_cyclonedx_components(
  values : Array[Json],
  parent : String,
  entries : Array[InventoryEntry],
  findings : Array[SbomImportFinding],
) -> Unit raise PurlError {
  for i = 0; i < values.length(); i = i + 1 {
    guard values[i] is Object(object) else {
      raise Syntax("CYCLONEDX_COMPONENT_OBJECT_REQUIRED", 0)
    }
    let fallback = if parent == "" {
      "component-" + i.to_string()
    } else {
      parent + "/component-" + i.to_string()
    }
    let record_id = match json_string_field(object, "bom-ref") {
      Some(value) => value
      None =>
        match json_string_field(object, "name") {
          Some(value) => value
          None => fallback
        }
    }
    import_one_purl(
      record_id,
      json_string_field(object, "purl"),
      entries,
      findings,
    )
    match object.get("components") {
      Some(Array(children)) =>
        collect_cyclonedx_components(children, record_id, entries, findings)
      Some(_) => raise Syntax("CYCLONEDX_COMPONENTS_ARRAY_REQUIRED", 0)
      None => ()
    }
  }
}

///|
fn finish_sbom_report(
  format : SbomFormat,
  entries : Array[InventoryEntry],
  findings : Array[SbomImportFinding],
) -> SbomImportReport {
  let mut imported = 0
  let mut missing = 0
  let mut invalid = 0
  for finding in findings {
    match finding.decision {
      Imported => imported += 1
      MissingPurl => missing += 1
      InvalidPurl => invalid += 1
    }
  }
  { format, entries, findings, imported, missing, invalid, }
}

///|
/// Import top-level and nested CycloneDX components from a JSON BOM. Every
/// component produces a finding; malformed PURLs do not abort sibling rows.
pub fn import_cyclonedx_json(
  input : String,
) -> SbomImportReport raise PurlError {
  let document = @json.parse(input) catch {
    _ => raise Syntax("INVALID_JSON", 0)
  }
  guard document is Object(root) else {
    raise Syntax("CYCLONEDX_OBJECT_REQUIRED", 0)
  }
  guard root.get("components") is Some(Array(components)) else {
    raise Syntax("CYCLONEDX_COMPONENTS_REQUIRED", 0)
  }
  let entries : Array[InventoryEntry] = []
  let findings : Array[SbomImportFinding] = []
  collect_cyclonedx_components(components, "", entries, findings)
  finish_sbom_report(CycloneDx, entries, findings)
}

///|
fn spdx_purl(object : Map[String, Json]) -> String? raise PurlError {
  match object.get("externalRefs") {
    None => return None
    Some(Array(references)) =>
      for value in references {
        guard value is Object(reference) else {
          raise Syntax("SPDX_EXTERNAL_REF_OBJECT_REQUIRED", 0)
        }
        let category = json_string_field(reference, "referenceCategory")
        let kind = json_string_field(reference, "referenceType")
        if category == Some("PACKAGE-MANAGER") &&
          (kind == Some("purl") || kind == Some("package-url")) {
          return json_string_field(reference, "referenceLocator")
        }
      }
    Some(_) => raise Syntax("SPDX_EXTERNAL_REFS_ARRAY_REQUIRED", 0)
  }
  None
}

///|
/// Import Package URL external references from SPDX JSON packages.
pub fn import_spdx_json(input : String) -> SbomImportReport raise PurlError {
  let document = @json.parse(input) catch {
    _ => raise Syntax("INVALID_JSON", 0)
  }
  guard document is Object(root) else {
    raise Syntax("SPDX_OBJECT_REQUIRED", 0)
  }
  guard root.get("packages") is Some(Array(packages)) else {
    raise Syntax("SPDX_PACKAGES_REQUIRED", 0)
  }
  let entries : Array[InventoryEntry] = []
  let findings : Array[SbomImportFinding] = []
  for i = 0; i < packages.length(); i = i + 1 {
    guard packages[i] is Object(package_object) else {
      raise Syntax("SPDX_PACKAGE_OBJECT_REQUIRED", 0)
    }
    let record_id = match json_string_field(package_object, "SPDXID") {
      Some(value) => value
      None =>
        match json_string_field(package_object, "name") {
          Some(value) => value
          None => "package-" + i.to_string()
        }
    }
    import_one_purl(record_id, spdx_purl(package_object), entries, findings)
  }
  finish_sbom_report(Spdx, entries, findings)
}

///|
/// Import and apply inventory policy in one downstream-facing operation.
pub fn audit_cyclonedx_json(
  input : String,
  policy~ : InventoryPolicy = InventoryPolicy::default(),
) -> SbomAuditReport raise PurlError {
  let import_report = import_cyclonedx_json(input)
  let inventory_report = audit_inventory(import_report.entries, policy~)
  { import_report, inventory_report, }
}

///|
/// Import and apply inventory policy in one downstream-facing operation.
pub fn audit_spdx_json(
  input : String,
  policy~ : InventoryPolicy = InventoryPolicy::default(),
) -> SbomAuditReport raise PurlError {
  let import_report = import_spdx_json(input)
  let inventory_report = audit_inventory(import_report.entries, policy~)
  { import_report, inventory_report, }
}

///|
/// Compare any two imported SBOM documents through canonical package-version
/// identities. This supports format migration checks such as CycloneDX to SPDX.
pub fn diff_sbom_imports(
  before : SbomImportReport,
  after : SbomImportReport,
) -> InventoryDelta {
  diff_inventory(before.entries, after.entries)
}
