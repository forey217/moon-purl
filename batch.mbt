///|
fn parse_finding_ok(
  index : Int,
  input : String,
  value : PackageUrl,
) -> ParseFinding {
  {
    index,
    input,
    canonical: value.to_string(),
    valid: true,
    code: "",
    offset: -1,
  }
}

///|
fn parse_finding_error(
  index : Int,
  input : String,
  code : String,
  offset : Int,
) -> ParseFinding {
  { index, input, canonical: "", valid: false, code, offset, }
}

///|
/// Parse a batch without allowing one malformed row to abort the remaining
/// input. Findings retain source order and carry stable error codes/offsets.
pub fn diagnose_batch(inputs : Array[String]) -> ParseReport {
  let findings : Array[ParseFinding] = []
  let mut valid = 0
  let mut invalid = 0
  for i = 0; i < inputs.length(); i = i + 1 {
    let value = parse(inputs[i]) catch {
      Syntax(code, offset) => {
        findings.push(parse_finding_error(i, inputs[i], code, offset))
        invalid += 1
        continue
      }
      Unsupported(code, offset) => {
        findings.push(parse_finding_error(i, inputs[i], code, offset))
        invalid += 1
        continue
      }
    }
    findings.push(parse_finding_ok(i, inputs[i], value))
    valid += 1
  }
  { findings, valid, invalid, }
}
