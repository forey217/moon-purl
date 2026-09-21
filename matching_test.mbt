///|
test "patterns support explicit fields and qualifier subsets" {
  let value = parse("pkg:npm/%40acme/widget@2.1.0?arch=arm64&os=linux")
  let pattern : PurlPattern = {
    package_type: Some("NPM"),
    namespace_parts: Some(["@acme"]),
    name: Some("widget"),
    version: Some("2.1.0"),
    qualifiers: [{ key: "os", value: "linux", }],
  }
  assert_eq(match_purl(value, pattern), Match)
}

///|
test "matching reports the first stable mismatch" {
  let value = parse("pkg:generic/acme/widget@2")
  assert_eq(
    match_purl(value, { ..PurlPattern::any(), package_type: Some("pypi"), }),
    TypeMismatch,
  )
  assert_eq(
    match_purl(value, { ..PurlPattern::any(), version: Some("3"), }),
    VersionMismatch,
  )
}

///|
test "same package version ignores artifact metadata" {
  let left = parse("pkg:generic/acme/widget@2?arch=arm64#bin")
  let right = parse("pkg:generic/acme/widget@2?arch=amd64#lib")
  let other = parse("pkg:generic/acme/widget@3")
  assert_true(same_package_version(left, right))
  assert_false(same_package_version(left, other))
}
