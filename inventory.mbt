///|
fn blocked_type(policy : InventoryPolicy, package_type : String) -> Bool {
  for value in policy.blocked_types {
    if ascii_lower(value) == package_type {
      return true
    }
  }
  false
}

///|
fn missing_required_qualifier(
  value : PackageUrl,
  policy : InventoryPolicy,
) -> String? {
  for required in policy.required_qualifiers {
    if !required_qualifier_matches(value, required) {
      return Some(ascii_lower(required.key))
    }
  }
  None
}

///|
fn inventory_finding(
  entry : InventoryEntry,
  canonical : String,
  decision : InventoryDecision,
  code : String,
  offset : Int,
) -> InventoryFinding {
  {
    record_id: entry.record_id,
    input: entry.purl,
    canonical,
    decision,
    code,
    offset,
  }
}

///|
fn seen_identity(values : Array[String], expected : String) -> Bool {
  for value in values {
    if value == expected {
      return true
    }
  }
  false
}

///|
/// Audit a structured PURL inventory without network access. Every input row
/// produces one finding. Duplicate means the same type/namespace/name/version
/// appeared earlier; qualifiers and subpath are excluded from that key, so the
/// result is a join warning rather than proof of byte-identical artifacts.
pub fn audit_inventory(
  entries : Array[InventoryEntry],
  policy? : InventoryPolicy = InventoryPolicy::default(),
) -> InventoryReport {
  let findings : Array[InventoryFinding] = []
  let identities : Array[String] = []
  let mut ready = 0
  let mut invalid = 0
  let mut unversioned = 0
  let mut duplicate = 0
  let mut policy_blocked = 0
  for entry in entries {
    let value = parse(entry.purl) catch {
      Syntax(code, offset) => {
        findings.push(inventory_finding(entry, "", Invalid, code, offset))
        invalid += 1
        continue
      }
      Unsupported(code, offset) => {
        findings.push(inventory_finding(entry, "", Invalid, code, offset))
        invalid += 1
        continue
      }
    }
    let canonical = value.to_string()
    let identity = value.identity()
    let finding = if policy.require_version && value.version is None {
      unversioned += 1
      inventory_finding(entry, canonical, Unversioned, "VERSION_REQUIRED", -1)
    } else if blocked_type(policy, value.package_type) {
      policy_blocked += 1
      inventory_finding(entry, canonical, PolicyBlocked, "TYPE_BLOCKED", -1)
    } else {
      match missing_required_qualifier(value, policy) {
        Some(key) => {
          policy_blocked += 1
          inventory_finding(
            entry,
            canonical,
            PolicyBlocked,
            "QUALIFIER_REQUIRED:" + key,
            -1,
          )
        }
        None =>
          if seen_identity(identities, identity) {
            duplicate += 1
            inventory_finding(
              entry,
              canonical,
              Duplicate,
              "DUPLICATE_IDENTITY",
              -1,
            )
          } else {
            ready += 1
            inventory_finding(entry, canonical, Ready, "", -1)
          }
      }
    }
    identities.push(identity)
    findings.push(finding)
  }
  { findings, ready, invalid, unversioned, duplicate, policy_blocked, }
}
