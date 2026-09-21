///|
/// Stable parser or policy error. Offsets are zero-based UTF-16 positions in
/// the original input. Error values never echo the input string.
pub(all) suberror PurlError {
  Syntax(String, Int)
  Unsupported(String, Int)
} derive(Eq, @debug.Debug)

///|
pub(all) struct Qualifier {
  key : String
  value : String
} derive(Eq, @debug.Debug)

///|
/// Package URL fields after decoding and profile normalization. Namespace is
/// represented as path segments so encoded slashes cannot be confused with
/// structural separators.
pub(all) struct PackageUrl {
  package_type : String
  namespace_parts : Array[String]
  name : String
  version : String?
  qualifiers : Array[Qualifier]
  subpath : Array[String]
} derive(Eq, @debug.Debug)

///|
pub(all) struct PurlPattern {
  package_type : String?
  namespace_parts : Array[String]?
  name : String?
  version : String?
  qualifiers : Array[Qualifier]
} derive(Eq, @debug.Debug)

///|
pub fn PurlPattern::any() -> PurlPattern {
  {
    package_type: None,
    namespace_parts: None,
    name: None,
    version: None,
    qualifiers: [],
  }
}

///|
pub(all) enum MatchResult {
  Match
  TypeMismatch
  NamespaceMismatch
  NameMismatch
  VersionMismatch
  QualifierMismatch(String)
} derive(Eq, @debug.Debug)

///|
pub(all) struct InventoryEntry {
  record_id : String
  purl : String
} derive(Eq, @debug.Debug)

///|
pub(all) enum InventoryDecision {
  Ready
  Invalid
  Unversioned
  Duplicate
  PolicyBlocked
} derive(Eq, @debug.Debug)

///|
pub fn InventoryDecision::to_string(self : InventoryDecision) -> String {
  match self {
    Ready => "ready"
    Invalid => "invalid"
    Unversioned => "unversioned"
    Duplicate => "duplicate"
    PolicyBlocked => "policy-blocked"
  }
}

///|
pub(all) struct InventoryFinding {
  record_id : String
  input : String
  canonical : String
  decision : InventoryDecision
  code : String
  offset : Int
} derive(Eq, @debug.Debug)

///|
pub(all) struct InventoryPolicy {
  require_version : Bool
  blocked_types : Array[String]
  required_qualifiers : Array[Qualifier]
} derive(Eq, @debug.Debug)

///|
pub fn InventoryPolicy::default() -> InventoryPolicy {
  { require_version: true, blocked_types: [], required_qualifiers: [], }
}

///|
pub(all) struct InventoryReport {
  findings : Array[InventoryFinding]
  ready : Int
  invalid : Int
  unversioned : Int
  duplicate : Int
  policy_blocked : Int
} derive(Eq, @debug.Debug)
