///|
fn sorted_unique(values : Array[String]) -> Array[String] {
  let out : Array[String] = []
  let seen : @hashset.HashSet[String] = @hashset.HashSet([])
  for value in values {
    if !seen.contains(value) {
      seen.add(value)
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
  let old_set : @hashset.HashSet[String] = @hashset.HashSet(old_values)
  let new_set : @hashset.HashSet[String] = @hashset.HashSet(new_values)
  let added : Array[String] = []
  let removed : Array[String] = []
  let unchanged : Array[String] = []
  for value in old_values {
    if new_set.contains(value) {
      unchanged.push(value)
    } else {
      removed.push(value)
    }
  }
  for value in new_values {
    if !old_set.contains(value) {
      added.push(value)
    }
  }
  { added, removed, unchanged, invalid_before, invalid_after, }
}
