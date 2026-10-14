///|
test "patterns support explicit fields and qualifier subsets" {
  let value = @moon_purl.parse(
    "pkg:npm/%40acme/widget@2.1.0?arch=arm64&os=linux",
  )
  let pattern : @moon_purl.PurlPattern = {
    package_type: Some("NPM"),
    namespace_parts: Some(["@acme"]),
    name: Some("widget"),
    version: Some("2.1.0"),
    qualifiers: [{ key: "os", value: "linux", }],
  }
  assert_eq(@moon_purl.match_purl(value, pattern), Match)
}

///|
test "matching reports the first stable mismatch" {
  let value = @moon_purl.parse("pkg:generic/acme/widget@2")
  assert_eq(
    @moon_purl.match_purl(value, {
      ..@moon_purl.PurlPattern::any(),
      package_type: Some("pypi"),
    }),
    TypeMismatch,
  )
  assert_eq(
    @moon_purl.match_purl(value, {
      ..@moon_purl.PurlPattern::any(),
      version: Some("3"),
    }),
    VersionMismatch,
  )
}

///|
test "same package version ignores artifact metadata" {
  let left = @moon_purl.parse("pkg:generic/acme/widget@2?arch=arm64#bin")
  let right = @moon_purl.parse("pkg:generic/acme/widget@2?arch=amd64#lib")
  let other = @moon_purl.parse("pkg:generic/acme/widget@3")
  assert_true(@moon_purl.same_package_version(left, right))
  assert_false(@moon_purl.same_package_version(left, other))
}
