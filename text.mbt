///|
fn ascii_lower(input : String) -> String {
  let out = StringBuilder()
  for i = 0; i < input.length(); i = i + 1 {
    let c = input[i].to_int()
    out.write_char(
      Int::unsafe_to_char(if c >= 65 && c <= 90 { c + 32 } else { c }),
    )
  }
  out.to_string()
}

///|
fn is_ascii_alnum(c : Int) -> Bool {
  (c >= 48 && c <= 57) || (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
}

///|
fn is_type_char(c : Int) -> Bool {
  is_ascii_alnum(c) || c == 46 || c == 43 || c == 45
}

///|
fn is_unreserved(c : Int) -> Bool {
  is_ascii_alnum(c) || c == 45 || c == 46 || c == 95 || c == 126
}

///|
fn hex_value(c : Int) -> Int {
  if c >= 48 && c <= 57 {
    c - 48
  } else if c >= 65 && c <= 70 {
    c - 55
  } else if c >= 97 && c <= 102 {
    c - 87
  } else {
    -1
  }
}

///|
fn upper_hex(value : Int) -> Char {
  "0123456789ABCDEF".to_array()[value]
}

///|
/// Decode percent triplets for ASCII bytes. Non-ASCII UTF-8 triplets are kept
/// in normalized uppercase form because this first release does not claim a
/// Unicode normalization profile.
fn decode_component(input : String, base : Int) -> String raise PurlError {
  let out = StringBuilder()
  let mut i = 0
  while i < input.length() {
    let c = input[i].to_int()
    if c != 37 {
      if c < 32 || c == 127 {
        raise Syntax("CONTROL_CHARACTER", base + i)
      }
      out.write_char(Int::unsafe_to_char(c))
      i += 1
      continue
    }
    if i + 2 >= input.length() {
      raise Syntax("BAD_PERCENT_ESCAPE", base + i)
    }
    let hi = hex_value(input[i + 1].to_int())
    let lo = hex_value(input[i + 2].to_int())
    if hi < 0 || lo < 0 {
      raise Syntax("BAD_PERCENT_ESCAPE", base + i)
    }
    let value = hi * 16 + lo
    if value < 128 {
      out.write_char(Int::unsafe_to_char(value))
    } else {
      out.write_char('%')
      out.write_char(upper_hex(hi))
      out.write_char(upper_hex(lo))
    }
    i += 3
  }
  out.to_string()
}

///|
fn encode_component(input : String, allow_colon? : Bool = false) -> String {
  let out = StringBuilder()
  for i = 0; i < input.length(); i = i + 1 {
    let c = input[i].to_int()
    if is_unreserved(c) || (allow_colon && c == 58) {
      out.write_char(Int::unsafe_to_char(c))
    } else if c < 128 {
      out.write_char('%')
      out.write_char(upper_hex((c >> 4) & 15))
      out.write_char(upper_hex(c & 15))
    } else {
      // Preserve already-normalized non-ASCII percent sequences or literal
      // Unicode. Full UTF-8 normalization is an explicit non-goal of 0.1.0.
      out.write_char(Int::unsafe_to_char(c))
    }
  }
  out.to_string()
}

///|
fn split_nonempty(
  input : String,
  separator : Int,
  base : Int,
  empty_code : String,
) -> Array[String] raise PurlError {
  let parts : Array[String] = []
  let mut start = 0
  for i = 0; i <= input.length(); i = i + 1 {
    if i == input.length() || input[i].to_int() == separator {
      if i == start {
        raise Syntax(empty_code, base + i)
      }
      parts.push(input[start:i].to_owned())
      start = i + 1
    }
  }
  parts
}

///|
fn normalize_pypi_name(name : String) -> String {
  let lower = ascii_lower(name)
  let out = StringBuilder()
  let mut separator = false
  for i = 0; i < lower.length(); i = i + 1 {
    let c = lower[i].to_int()
    if c == 45 || c == 46 || c == 95 {
      if !separator {
        out.write_char('-')
        separator = true
      }
    } else {
      out.write_char(Int::unsafe_to_char(c))
      separator = false
    }
  }
  out.to_string()
}
