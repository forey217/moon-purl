///|
fn parse_rejected(input : String) -> Bool {
  try {
    ignore(parse(input))
    false
  } catch {
    _ => true
  }
}

///|
test "canonical examples from common package ecosystems" {
  let cases : Array[(String, String)] = [
    (
      "pkg:PyPI/Django_rest.framework@3.15.1", "pkg:pypi/django-rest-framework@3.15.1",
    ),
    (
      "pkg:npm/%40Angular/Core@12.3.1?Repository_URL=https:%2f%2fexample.com", "pkg:npm/%40angular/core@12.3.1?repository_url=https:%2F%2Fexample.com",
    ),
    (
      "pkg:maven/org.apache.commons/io@1.3.4?classifier=sources&type=jar", "pkg:maven/org.apache.commons/io@1.3.4?classifier=sources&type=jar",
    ),
    (
      "pkg:golang/github.com/package-url/packageurl-go@v0.1.0#internal/parser", "pkg:golang/github.com/package-url/packageurl-go@v0.1.0#internal/parser",
    ),
  ]
  for (input, expected) in cases {
    assert_eq(canonicalize(input), expected)
  }
}

///|
test "parser exposes decoded structured fields" {
  let value = parse(
    "pkg:maven/org.example/widget@2.0.0?arch=x86_64&repository_url=https:%2F%2Frepo.example#dist/linux",
  )
  assert_eq(value.package_type, "maven")
  assert_eq(value.namespace_parts, ["org.example"])
  assert_eq(value.name, "widget")
  assert_eq(value.version, Some("2.0.0"))
  assert_eq(value.qualifier("arch"), Some("x86_64"))
  assert_eq(value.subpath, ["dist", "linux"])
}

///|
test "qualifiers are sorted and keys are case-insensitive" {
  assert_eq(
    canonicalize("pkg:generic/demo@1?Z=last&a=first&M=middle"),
    "pkg:generic/demo@1?a=first&m=middle&z=last",
  )
}

///|
test "identity omits qualifiers and subpath only" {
  let value = parse("pkg:generic/acme/widget@1.0?arch=arm64#bin/tool")
  assert_eq(value.identity(), "pkg:generic/acme/widget@1.0")
}

///|
test "invalid structure is rejected deterministically" {
  let bad : Array[String] = [
    "", "http:generic/name@1", "pkg:/name@1", "pkg:generic/", "pkg:generic/name@",
    "pkg:generic/name?", "pkg:generic/name?a=1&a=2", "pkg:generic/name?=value", "pkg:generic/name#../escape",
    "pkg:generic/name#one//two", "pkg:pypi/acme/widget@1", "pkg:npm/scope/name@1",
  ]
  for input in bad {
    assert_true(parse_rejected(input))
  }
}

///|
test "error offsets identify the failing percent escape" {
  let mut observed = -1
  ignore(parse("pkg:generic/demo@1?source=%Q0")) catch {
    Syntax(code, offset) => {
      assert_eq(code, "BAD_PERCENT_ESCAPE")
      observed = offset
    }
    _ => ()
  }
  assert_eq(observed, 26)
}
