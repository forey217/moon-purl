///|
fn contains_string(values : Array[String], expected : String) -> Bool {
  for value in values {
    if value == expected {
      return true
    }
  }
  false
}

///|
fn sorted_unique(values : Array[String]) -> Array[String] {
  let out : Array[String] = []
  for value in values {
    if !contains_string(out, value) {
      out.push(value)
    }
  }
  out.sort_by(fn(a, b) { String::lexical_compare(a, b) })
  out
}

///|
fn snapshot_identities(entries : Array[InventoryEntry]) -> (Array[String], Int) {
  let identities : Array[String] = []
  let mut invalid = 0
  for entry in entries {
    let value = parse(entry.purl) catch {
      _ => {
        invalid += 1
        continue
      }
    }
    identities.push(value.identity())
  }
  (sorted_unique(identities), invalid)
}

///|
/// Compare two inventories using normalized package-version identity. Artifact
/// qualifiers and subpaths are excluded, matching vulnerability-database join
/// behavior. Results are sorted so CI output is independent of input ordering.
pub fn diff_inventory(
  before : Array[InventoryEntry],
  after : Array[InventoryEntry],
) -> InventoryDelta {
  let (old_values, invalid_before) = snapshot_identities(before)
  let (new_values, invalid_after) = snapshot_identities(after)
  let added : Array[String] = []
  let removed : Array[String] = []
  let unchanged : Array[String] = []
  for value in old_values {
    if contains_string(new_values, value) {
      unchanged.push(value)
    } else {
      removed.push(value)
    }
  }
  for value in new_values {
    if !contains_string(old_values, value) {
      added.push(value)
    }
  }
  { added, removed, unchanged, invalid_before, invalid_after, }
}
