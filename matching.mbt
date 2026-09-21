///|
fn string_arrays_equal(left : Array[String], right : Array[String]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i = 0; i < left.length(); i = i + 1 {
    if left[i] != right[i] {
      return false
    }
  }
  true
}

///|
fn required_qualifier_matches(value : PackageUrl, expected : Qualifier) -> Bool {
  match value.qualifier(expected.key) {
    Some(actual) => actual == expected.value
    None => false
  }
}

///|
/// Match a parsed Package URL against explicit fields. Missing pattern fields
/// are wildcards; present fields are exact after profile normalization.
/// Qualifier requirements are a subset match and subpath is intentionally
/// ignored. The first mismatch is returned for stable CI diagnostics.
pub fn match_purl(value : PackageUrl, pattern : PurlPattern) -> MatchResult {
  match pattern.package_type {
    Some(expected) =>
      if value.package_type != ascii_lower(expected) {
        return TypeMismatch
      }
    None => ()
  }
  match pattern.namespace_parts {
    Some(expected) =>
      if !string_arrays_equal(value.namespace_parts, expected) {
        return NamespaceMismatch
      }
    None => ()
  }
  match pattern.name {
    Some(expected) => if value.name != expected { return NameMismatch }
    None => ()
  }
  match pattern.version {
    Some(expected) =>
      match value.version {
        Some(actual) => if actual != expected { return VersionMismatch }
        None => return VersionMismatch
      }
    None => ()
  }
  for expected in pattern.qualifiers {
    if !required_qualifier_matches(value, expected) {
      return QualifierMismatch(expected.key)
    }
  }
  Match
}

///|
pub fn matches(value : PackageUrl, pattern : PurlPattern) -> Bool {
  match_purl(value, pattern) == Match
}

///|
/// Join two PURLs on type/namespace/name/version while deliberately ignoring
/// qualifiers and subpath. Callers must still compare artifact digests when
/// they need byte identity.
pub fn same_package_version(left : PackageUrl, right : PackageUrl) -> Bool {
  left.identity() == right.identity()
}
