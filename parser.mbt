///|
fn find_first(input : String, needle : Int32, start : Int32) -> Int32 {
  for i = start; i < input.length(); i = i + 1 {
    if input[i].to_int() == needle {
      return i
    }
  }
  -1
}

///|
fn find_last(
  input : String,
  needle : Int32,
  start : Int32,
  end : Int32,
) -> Int32 {
  let mut found = -1
  for i = start; i < end; i = i + 1 {
    if input[i].to_int() == needle {
      found = i
    }
  }
  found
}

///|
fn validate_type(value : String, offset : Int32) -> Unit raise PurlError {
  if value.length() == 0 {
    raise Syntax("EMPTY_TYPE", offset)
  }
  for i = 0; i < value.length(); i = i + 1 {
    if !is_type_char(value[i].to_int()) {
      raise Syntax("INVALID_TYPE", offset + i)
    }
  }
  if !is_ascii_alnum(value[0].to_int()) {
    raise Syntax("INVALID_TYPE", offset)
  }
}

///|
fn validate_path_segment(
  value : String,
  offset : Int32,
  code : String,
) -> Unit raise PurlError {
  if value.length() == 0 {
    raise Syntax(code, offset)
  }
  if value == "." || value == ".." {
    raise Syntax("DOT_PATH_SEGMENT", offset)
  }
  for i = 0; i < value.length(); i = i + 1 {
    let c = value[i].to_int()
    if c == 47 || c == 92 || c == 63 || c == 35 {
      raise Syntax(code, offset + i)
    }
  }
}

///|
fn validate_qualifier_key(
  value : String,
  offset : Int32,
) -> Unit raise PurlError {
  if value.length() == 0 {
    raise Syntax("EMPTY_QUALIFIER_KEY", offset)
  }
  for i = 0; i < value.length(); i = i + 1 {
    let c = value[i].to_int()
    if !(is_ascii_alnum(c) || c == 46 || c == 45 || c == 95) {
      raise Syntax("INVALID_QUALIFIER_KEY", offset + i)
    }
  }
}

///|
fn qualifier_index(values : Array[Qualifier], key : String) -> Int32 {
  for i = 0; i < values.length(); i = i + 1 {
    if values[i].key == key {
      return i
    }
  }
  -1
}

///|
fn sort_qualifiers(values : Array[Qualifier]) -> Array[Qualifier] {
  let out : Array[Qualifier] = []
  for value in values {
    out.push(value)
  }
  out.sort_by(fn(a, b) { String::lexical_compare(a.key, b.key) })
  out
}

///|
fn parse_qualifiers(
  raw : String,
  base : Int32,
) -> Array[Qualifier] raise PurlError {
  if raw.length() == 0 {
    raise Syntax("EMPTY_QUALIFIERS", base)
  }
  let pairs = split_nonempty(raw, 38, base, "EMPTY_QUALIFIER")
  let out : Array[Qualifier] = []
  let mut cursor = base
  for pair in pairs {
    let equals = find_first(pair, 61, 0)
    if equals <= 0 || equals == pair.length() - 1 {
      raise Syntax("INVALID_QUALIFIER", cursor)
    }
    if find_first(pair, 61, equals + 1) >= 0 {
      raise Syntax("INVALID_QUALIFIER", cursor + equals + 1)
    }
    let key = ascii_lower(decode_component(pair[0:equals].to_owned(), cursor))
    let value = decode_component(
      pair[equals + 1:pair.length()].to_owned(),
      cursor + equals + 1,
    )
    validate_qualifier_key(key, cursor)
    if value.length() == 0 {
      raise Syntax("EMPTY_QUALIFIER_VALUE", cursor + equals + 1)
    }
    if qualifier_index(out, key) >= 0 {
      raise Syntax("DUPLICATE_QUALIFIER", cursor)
    }
    out.push({ key, value, })
    cursor += pair.length() + 1
  }
  sort_qualifiers(out)
}

///|
fn parse_subpath(raw : String, base : Int32) -> Array[String] raise PurlError {
  if raw.length() == 0 {
    raise Syntax("EMPTY_SUBPATH", base)
  }
  let raw_parts = split_nonempty(raw, 47, base, "EMPTY_SUBPATH_SEGMENT")
  let out : Array[String] = []
  let mut cursor = base
  for part in raw_parts {
    let decoded = decode_component(part, cursor)
    validate_path_segment(decoded, cursor, "INVALID_SUBPATH")
    out.push(decoded)
    cursor += part.length() + 1
  }
  out
}

///|
fn normalize_profile(value : PackageUrl) -> PackageUrl raise PurlError {
  let package_type = ascii_lower(value.package_type)
  let mut namespace_parts = value.namespace_parts
  let mut name = value.name
  match package_type {
    "pypi" => {
      if namespace_parts.length() > 0 {
        raise Unsupported("PYPI_NAMESPACE", 4)
      }
      name = normalize_pypi_name(name)
    }
    "npm" => {
      if namespace_parts.length() > 1 {
        raise Unsupported("NPM_NAMESPACE_DEPTH", 4)
      }
      if namespace_parts.length() == 1 && !namespace_parts[0].has_prefix("@") {
        raise Unsupported("NPM_SCOPE", 4)
      }
      name = ascii_lower(name)
      if namespace_parts.length() == 1 {
        namespace_parts = [ascii_lower(namespace_parts[0])]
      }
    }
    "github" => {
      if namespace_parts.length() == 0 {
        raise Unsupported("NAMESPACE_REQUIRED", 4)
      }
      // The GitHub PURL type requires lowercase owner and repository names.
      // Tags and other version values retain their original spelling.
      namespace_parts = namespace_parts.map(ascii_lower)
      name = ascii_lower(name)
    }
    "maven" | "golang" =>
      if namespace_parts.length() == 0 {
        raise Unsupported("NAMESPACE_REQUIRED", 4)
      }
    _ => ()
  }
  { ..value, package_type, namespace_parts, name, }
}

///|
/// Parse the ASCII interoperability profile of the Package URL specification.
/// Structural separators must be literal and data separators percent-encoded.
/// Known ecosystems receive conservative profile checks; unknown valid types
/// remain usable through the generic grammar.
pub fn parse(input : String) -> PackageUrl raise PurlError {
  if input.length() < 6 || ascii_lower(input[0:4].to_owned()) != "pkg:" {
    raise Syntax("EXPECTED_PKG_SCHEME", 0)
  }
  let hash = find_first(input, 35, 4)
  let fragment_end = if hash < 0 { input.length() } else { hash }
  if hash >= 0 && find_first(input, 35, hash + 1) >= 0 {
    raise Syntax("MULTIPLE_FRAGMENT", hash + 1)
  }
  let question = find_first(input, 63, 4)
  if question >= 0 && question > fragment_end {
    raise Syntax("QUERY_AFTER_FRAGMENT", question)
  }
  if question >= 0 && find_first(input, 63, question + 1) >= 0 {
    raise Syntax("MULTIPLE_QUERY", question + 1)
  }
  let path_end = if question < 0 { fragment_end } else { question }
  let slash = find_first(input, 47, 4)
  if slash < 0 || slash >= path_end {
    raise Syntax("EXPECTED_NAME_PATH", 4)
  }
  let package_type = input[4:slash].to_owned()
  validate_type(package_type, 4)
  let at = find_last(input, 64, slash + 1, path_end)
  let name_end = if at < 0 { path_end } else { at }
  if at >= 0 && at == path_end - 1 {
    raise Syntax("EMPTY_VERSION", at + 1)
  }
  let raw_path = input[slash + 1:name_end].to_owned()
  let raw_segments = split_nonempty(
    raw_path,
    47,
    slash + 1,
    "EMPTY_PACKAGE_SEGMENT",
  )
  let decoded : Array[String] = []
  let mut cursor = slash + 1
  for segment in raw_segments {
    let value = decode_component(segment, cursor)
    validate_path_segment(value, cursor, "INVALID_PACKAGE_SEGMENT")
    decoded.push(value)
    cursor += segment.length() + 1
  }
  let name = decoded[decoded.length() - 1]
  let namespace_parts : Array[String] = []
  for i = 0; i < decoded.length() - 1; i = i + 1 {
    namespace_parts.push(decoded[i])
  }
  let version = if at < 0 {
    None
  } else {
    Some(decode_component(input[at + 1:path_end].to_owned(), at + 1))
  }
  let qualifiers = if question < 0 {
    []
  } else {
    parse_qualifiers(input[question + 1:fragment_end].to_owned(), question + 1)
  }
  let subpath = if hash < 0 {
    []
  } else {
    parse_subpath(input[hash + 1:input.length()].to_owned(), hash + 1)
  }
  normalize_profile({
    package_type,
    namespace_parts,
    name,
    version,
    qualifiers,
    subpath,
  })
}
