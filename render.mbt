///|
fn join_encoded(parts : Array[String]) -> String {
  let out = StringBuilder()
  for i = 0; i < parts.length(); i = i + 1 {
    if i > 0 {
      out.write_char('/')
    }
    out.write_string(encode_component(parts[i]))
  }
  out.to_string()
}

///|
/// Return canonical spelling for the supported profile: lowercase scheme/type,
/// normalized type-specific name, sorted lowercase qualifier keys and uppercase
/// percent triplets for ASCII reserved data.
pub fn PackageUrl::to_string(self : PackageUrl) -> String {
  let out = StringBuilder()
  out.write_string("pkg:" + ascii_lower(self.package_type) + "/")
  if self.namespace_parts.length() > 0 {
    out.write_string(join_encoded(self.namespace_parts))
    out.write_char('/')
  }
  out.write_string(encode_component(self.name))
  match self.version {
    Some(version) => {
      out.write_char('@')
      out.write_string(encode_component(version))
    }
    None => ()
  }
  if self.qualifiers.length() > 0 {
    out.write_char('?')
    let qualifiers = sort_qualifiers(self.qualifiers)
    for i = 0; i < qualifiers.length(); i = i + 1 {
      if i > 0 {
        out.write_char('&')
      }
      out.write_string(ascii_lower(qualifiers[i].key))
      out.write_char('=')
      out.write_string(encode_component(qualifiers[i].value, allow_colon=true))
    }
  }
  if self.subpath.length() > 0 {
    out.write_char('#')
    out.write_string(join_encoded(self.subpath))
  }
  out.to_string()
}

///|
pub fn canonicalize(input : String) -> String raise PurlError {
  parse(input).to_string()
}

///|
/// Identity used for vulnerability joins and deduplication. Qualifiers and
/// subpath are intentionally excluded; the result retains type, namespace,
/// name and version. This is not a statement that two artifacts are identical.
pub fn PackageUrl::identity(self : PackageUrl) -> String {
  { ..self, qualifiers: [], subpath: [], }.to_string()
}

///|
pub fn PackageUrl::qualifier(self : PackageUrl, key : String) -> String? {
  let expected = ascii_lower(key)
  for item in self.qualifiers {
    if item.key == expected {
      return Some(item.value)
    }
  }
  None
}
