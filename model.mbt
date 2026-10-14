///|
/// Stable parser or policy error. Offsets are zero-based UTF-16 positions in
/// the original input. Error values never echo the input string.
pub(all) suberror PurlError {
  Syntax(String, Int32)
  Unsupported(String, Int32)
} derive(Eq, @debug.Debug)

///|
pub extend PurlError with Eq::{equal, not_equal}

///|
pub extend PurlError with @debug.Debug::{to_repr}

///|
pub(all) struct Qualifier {
  key : String
  value : String
} derive(Eq, @debug.Debug)

///|
pub extend Qualifier with Eq::{equal, not_equal}

///|
pub extend Qualifier with @debug.Debug::{to_repr}

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
pub extend PackageUrl with Eq::{equal, not_equal}

///|
pub extend PackageUrl with @debug.Debug::{to_repr}

///|
pub(all) struct PurlPattern {
  package_type : String?
  namespace_parts : Array[String]?
  name : String?
  version : String?
  qualifiers : Array[Qualifier]
} derive(Eq, @debug.Debug)

///|
pub extend PurlPattern with Eq::{equal, not_equal}

///|
pub extend PurlPattern with @debug.Debug::{to_repr}

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
pub extend MatchResult with Eq::{equal, not_equal}

///|
pub extend MatchResult with @debug.Debug::{to_repr}

///|
pub(all) struct InventoryEntry {
  record_id : String
  purl : String
} derive(Eq, @debug.Debug)

///|
pub extend InventoryEntry with Eq::{equal, not_equal}

///|
pub extend InventoryEntry with @debug.Debug::{to_repr}

///|
pub(all) enum InventoryDecision {
  Ready
  Invalid
  Unversioned
  Duplicate
  PolicyBlocked
} derive(Eq, @debug.Debug)

///|
pub extend InventoryDecision with Eq::{equal, not_equal}

///|
pub extend InventoryDecision with @debug.Debug::{to_repr}

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
  offset : Int32
} derive(Eq, @debug.Debug)

///|
pub extend InventoryFinding with Eq::{equal, not_equal}

///|
pub extend InventoryFinding with @debug.Debug::{to_repr}

///|
pub(all) struct InventoryPolicy {
  require_version : Bool
  blocked_types : Array[String]
  required_qualifiers : Array[Qualifier]
} derive(Eq, @debug.Debug)

///|
pub extend InventoryPolicy with Eq::{equal, not_equal}

///|
pub extend InventoryPolicy with @debug.Debug::{to_repr}

///|
pub fn InventoryPolicy::default() -> InventoryPolicy {
  { require_version: true, blocked_types: [], required_qualifiers: [], }
}

///|
pub(all) struct InventoryReport {
  findings : Array[InventoryFinding]
  ready : Int32
  invalid : Int32
  unversioned : Int32
  duplicate : Int32
  policy_blocked : Int32
} derive(Eq, @debug.Debug)

///|
pub extend InventoryReport with Eq::{equal, not_equal}

///|
pub extend InventoryReport with @debug.Debug::{to_repr}

///|
pub(all) struct ParseFinding {
  index : Int32
  input : String
  canonical : String
  valid : Bool
  code : String
  offset : Int32
} derive(Eq, @debug.Debug)

///|
pub extend ParseFinding with Eq::{equal, not_equal}

///|
pub extend ParseFinding with @debug.Debug::{to_repr}

///|
pub(all) struct ParseReport {
  findings : Array[ParseFinding]
  valid : Int32
  invalid : Int32
} derive(Eq, @debug.Debug)

///|
pub extend ParseReport with Eq::{equal, not_equal}

///|
pub extend ParseReport with @debug.Debug::{to_repr}

///|
/// Identity-level change set between two dependency snapshots. Duplicate rows
/// collapse to one identity; invalid rows are counted but never compared.
pub(all) struct InventoryDelta {
  added : Array[String]
  removed : Array[String]
  unchanged : Array[String]
  invalid_before : Int32
  invalid_after : Int32
} derive(Eq, @debug.Debug)

///|
pub extend InventoryDelta with Eq::{equal, not_equal}

///|
pub extend InventoryDelta with @debug.Debug::{to_repr}

///|
pub(all) enum SbomFormat {
  CycloneDx
  Spdx
} derive(Eq, @debug.Debug)

///|
pub extend SbomFormat with Eq::{equal, not_equal}

///|
pub extend SbomFormat with @debug.Debug::{to_repr}

///|
pub(all) enum SbomImportDecision {
  Imported
  MissingPurl
  InvalidPurl
} derive(Eq, @debug.Debug)

///|
pub extend SbomImportDecision with Eq::{equal, not_equal}

///|
pub extend SbomImportDecision with @debug.Debug::{to_repr}

///|
pub(all) struct SbomImportFinding {
  record_id : String
  decision : SbomImportDecision
  input : String
  canonical : String
  code : String
  offset : Int32
} derive(Eq, @debug.Debug)

///|
pub extend SbomImportFinding with Eq::{equal, not_equal}

///|
pub extend SbomImportFinding with @debug.Debug::{to_repr}

///|
pub(all) struct SbomImportReport {
  format : SbomFormat
  entries : Array[InventoryEntry]
  findings : Array[SbomImportFinding]
  imported : Int32
  missing : Int32
  invalid : Int32
} derive(Eq, @debug.Debug)

///|
pub extend SbomImportReport with Eq::{equal, not_equal}

///|
pub extend SbomImportReport with @debug.Debug::{to_repr}

///|
pub(all) struct SbomAuditReport {
  import_report : SbomImportReport
  inventory_report : InventoryReport
} derive(Eq, @debug.Debug)

///|
pub extend SbomAuditReport with Eq::{equal, not_equal}

///|
pub extend SbomAuditReport with @debug.Debug::{to_repr}
