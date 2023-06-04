#let _strfmt_formatparser(s) = {
  if type(s) != "string" {
    panic("String format parser given non-string.")
  }
  let result = ()
  let codepoints = s.codepoints()

  // -- parsing state --
  let current-fmt-span = none
  let current-fmt-name = none
  // if the last character was an unescaped {
  let last-was-lbracket = false
  // if the last character was an unescaped }
  let last-was-rbracket = false
  let last-i = 0

  // -- procedures --
  let write-format-span(i, result, current-fmt-span, current-fmt-name) = {
    current-fmt-span.at(1) = i  // end index
    result.push((format: (name: current-fmt-name, span: current-fmt-span)))
    current-fmt-span = none
    current-fmt-name = none
    (result, current-fmt-span, current-fmt-name)
  }

  // -- errors --
  let excessive-lbracket() = {
    panic("String format parsing error: Inserted a second, non-escaped { inside a {format specifier}. Did you forget to insert a } somewhere?")
  }
  let excessive-rbracket() = {
    panic("String format parsing error: Inserted a stray } (doesn't match any { from before). Did you forget to insert a { somewhere?")
  }
  let missing-rbracket() = {
    panic("String format parsing error: Reached end of string with an open format specifier {, but without a closing }. Did you forget to insert a right bracket?")
  }

  // -- parse loop --
  for (i, character) in codepoints.enumerate() {
    last-i = i
    if character == "{" {
      // double l-bracket = escape
      if last-was-lbracket {
        last-was-lbracket = false  // escape {{
        last-was-rbracket = false
        current-fmt-name += character
        if current-fmt-span.at(0) == i - 1 {
          current-fmt-span = none  // cancel this span
        }
        result.push((escape: (escaped: "{", span: (i - 1, i + 1))))
        continue
      }
      if last-was-rbracket {
        // { ... }{ <--- ok, close the previous span
        (result, current-fmt-span, current-fmt-name) = write-format-span(i, result, current-fmt-span, current-fmt-name)
        last-was-rbracket = false
      }
      // already had a { before this, but not immediately before
      if current-fmt-span != none {
        excessive-lbracket()
      }
      // begin span
      current-fmt-span = (i, none)
      current-fmt-name = ""
      last-was-lbracket = true
    } else if character == "}" {
      last-was-lbracket = false
      if last-was-rbracket {
        last-was-rbracket = false  // escape }}
        current-fmt-name += character
        result.push((escape: (escaped: "}", span: (i - 1, i + 1))))
        continue
      }
      // delay closing the span to the next iteration
      // in case this is an escaped }
      last-was-rbracket = true
    } else {
      // { ... {A  <--- non-escaped { inside larger {}
      if last-was-lbracket and (current-fmt-span != none and current-fmt-span.at(0) != i - 1) {
        excessive-lbracket()
      }
      if last-was-rbracket {
        if current-fmt-span == none {
          // {...} }A <--- non-escaped } with no matching {
          excessive-rbracket()
        } else {
          // { ... }A <--- ok, close the previous span
          (result, current-fmt-span, current-fmt-name) = write-format-span(i, result, current-fmt-span, current-fmt-name)
        }
      }
      // {abc <--- add character to the format name
      if current-fmt-name != none {
        current-fmt-name += character
      }
      last-was-lbracket = false
      last-was-rbracket = false
    }
  }
  // { ...
  if current-fmt-span != none {
    if last-was-rbracket {
      // ... } <--- ok, close span
      (result, current-fmt-span, current-fmt-name) = write-format-span(last-i + 1, result, current-fmt-span, current-fmt-name)
    } else {
      // {abcd| <--- string ended with unclosed span
      missing-rbracket()
    }
  }

  result
}

#let _strfmt_parse-fmt-name(name) = {
  // {a:b} => separate 'a' from 'b'
  // (also accepts {a}, {}, {0}, {:...})
  let subparts = name.match(regex("^([^:]*)(?::(.*))?$")).captures
  let name = subparts.at(0)
  let extras = subparts.at(1)
  let name = if type(name) != "string" {
    name
  } else if name == "" {
    none
  } else if regex("^\\d+$") in name {
    int(name)
  } else {
    name
  }
  (name, extras)
}

#let _strfmt_is-numeric-type(obj) = {
  type(obj) in ("integer", "float")
}

#let _strfmt_stringify(obj) = {
  if type(obj) in ("integer", "float", "label", "string") {
    str(obj)
  } else {
    repr(obj)
  }
}

#let _strfmt_display-radix(num, radix, signed: true, lowercase: false) = {
  let num = int(num)
  if type(radix) != "integer" or num == 0 or radix <= 1 {
    return "0"
  }
  let sign = if num < 0 and signed { "-" } else { "" }
  let num = calc.abs(num)
  let radix = calc.min(radix, 16)
  let digits = if lowercase {
    ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f")
  } else {
    ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F")
  }
  let result = ""

  while (num > 0) {
    let quot = calc.quo(num, radix)
    let rem = calc.floor(calc.rem(num, radix))
    let digit = digits.at(rem)
    result = digit + result
    num = quot
  }

  sign + result
}

#let _strfmt_with-precision(num, precision) = {
  if precision == none {
    return _strfmt_stringify(num)
  }
  let result = _strfmt_stringify(calc.round(float(num), digits: calc.min(50, precision)))
  let digits-match = result.match(regex("^\\d+\\.(\\d+)$"))
  if digits-match != none and digits-match.captures.len() > 0 {
    let digits = digits-match.captures.first()
    let digits-len-diff = precision - digits.len()
    // add missing zeroes for precision
    if digits-len-diff > 0 {
      result += "0" * digits-len-diff
    }
  }

  result
}

#let _strfmt_exp-format(num, exponent-sign: "e", base: 10, precision: none) = {
  assert(_strfmt_is-numeric-type(num), message: "String formatter internal error: Cannot convert '" + repr(num) + "' to a number for exponent calculation.")
  let f = float(num)
  let exponent = if f == 0 { 1 } else { calc.floor(calc.log(calc.abs(f), base: base)) }
  let mantissa = f / calc.pow(10, exponent)
  let mantissa = _strfmt_with-precision(mantissa, precision)

  mantissa + exponent-sign + str(exponent)
}

// Parses {format:specslikethis}.
// Rust's format spec grammar:
/*
format_spec := [[fill]align][sign]['#']['0'][width]['.' precision]type
fill := character
align := '<' | '^' | '>'
sign := '+' | '-'
width := count
precision := count | '*'
type := '' | '?' | 'x?' | 'X?' | identifier
count := parameter | integer
parameter := argument '$'
*/
#let _generate-replacement(fullname, extras, replacement, pos-replacements: (), named-replacements: (:)) = {
  if extras == none {
    return _strfmt_stringify(replacement)
  }
  let extras = _strfmt_stringify(extras)
  // note: usage of [\s\S] in regex to include all characters, incl. newline
  // (dot format ignores newline)
  let extra-parts = extras.match(
    //           fill      align    sign   #   0     width(from param)      width      precision(from param)    precision  spectype
    regex("^(?:([\\s\\S])?([<^>]))?([+-])?(#)?(0)?(?:(?:(\\d+)|([^.$]+))\$|(\\d+))?(?:\\.(?:(?:(\\d+)|([^$]+))\$|(\\d+)))?([^\\s]*)\\s*$")
  )
  if extra-parts == none {
    panic("String formatter error: Invalid format spec '" + extras + "', from '{" + fullname + "}'. Try escaping the braces { } with {{ }} if you wanted to insert literal braces.")
  }

  let (fill, align, sign, hashtag, zero, width-posarg, width-namedarg, width-lit, precision-posarg, precision-namedarg, precision-lit, spectype) = extra-parts.captures

  // 'count' type parameters in the spec (width, precision) can be either a literal number (123),
  // a number referring to a positional argument (123$), or some text referring to a named argument (abc$).
  // The final $ is mandatory for the last two cases.
  let parse-count(lit, pos, named, spec-part-name: "unknown") = {
    if lit != none {
      int(lit)
    } else if pos != none {
      let i = int(pos)
      assert(
        pos-replacements.len() > 0,
        message: "String formatter error: Attempted to use positional argument " + str(i) + " for " + spec-part-name + ", but no positional arguments were given (from '" + fullname + "')."
      )
      assert(
        i >= 0 and i < pos-replacements.len(),
        message: "String formatter error: Attempted to use positional argument " + str(i) + " for " + spec-part-name + ", but there is no argument at that position (from '" + fullname + "'). Please note that positional arguments start at position 0, and are specified in order after the format string in the 'strfmt' call."
      )
      let arg = pos-replacements.at(i)
      assert(
        type(arg) == "integer",
        message: "String formatter error: Attempted to use positional argument " + str(i) + " for " + spec-part-name + ", but it was a(n) '" + type(arg) + "', not an integer (from '" + fullname + "')."
      )

      int(arg)
    } else if named != none {
      assert(
        named-replacements.len() > 0,
        message: "String formatter error: Attempted to use named argument '" + named + "' for " + spec-part-name + ", but no named arguments were given (from '" + fullname + "')."
      )
      assert(
        named in named-replacements,
        message: "String formatter error: Attempted to use named argument '" + named + "' for " + spec-part-name + ", but there is no argument associated to that name (from '" + fullname + "'). Ensure you pass that argument in the 'strfmt' call, e.g. strfmt(\"format...\", " + named + ": 20)."
      )
      let arg = named-replacements.at(named)
      assert(
        type(arg) == "integer",
        message: "String formatter error: Attempted to use named argument '" + named + "' for " + spec-part-name + ", but it was a(n) '" + type(arg) + "', not an integer (from '" + fullname + "')."
      )

      int(arg)
    } else {
      none
    }
  }

  let align = if align == "" {
    none
  } else if align == "<" {
    left
  } else if align == ">" {
    right
  } else if align == "^" {
    center
  } else if align != none {
    panic("String formatter error: Invalid alignment in the format spec: '" + align + "' (must be either '<', '^' or '>').")
  }
  let width = parse-count(width-lit, width-posarg, width-namedarg, spec-part-name: "width")
  let width = if width == none { 0 } else { int(width) }
  let precision = parse-count(precision-lit, precision-posarg, precision-namedarg, spec-part-name: "precision")
  let hashtag = hashtag == "#"
  let zero = zero == "0"
  let hashtag-prefix = ""

  let valid-specs = ("", "?", "b", "x", "X", "o", "x?", "X?", "e", "E")
  let spec-error() = {
    panic(
      "String formatter error: Unknown spec type '" + spectype + "', from '{" + fullname + "}'. Valid options include: '" + valid-specs.join("', '") + "'. Maybe you specified some invalid formatting spec syntax (after the ':'), which can also prompt this error. Check the typst-strfmt docs for more information.")
  }
  if spectype not in valid-specs {
    spec-error()
  }

  let is-numeric = _strfmt_is-numeric-type(replacement)
  if is-numeric {
    if zero {
      // disable fill, we will be prefixing with zeroes if necessary
      fill = none
    } else if fill == none {
      fill = " "
      zero = false
    }
    // default number alignment to right
    if align == none {
      align = right
    }

    // if + is specified, + will appear before all numbers >= 0.
    if sign == "+" and replacement >= 0 {
      sign = "+"
    } else if replacement < 0 {
      sign = "-"
    } else {
      sign = ""
    }

    if spectype in ("e", "E") {
      let exponent-sign = if spectype == "E" { "E" } else { "e" }
      replacement = _strfmt_exp-format(calc.abs(replacement), exponent-sign: exponent-sign, precision: precision)
    } else if type(replacement) != "integer" and precision != none {
      replacement = _strfmt_with-precision(replacement, precision)
    } else if type(replacement) == "integer" and spectype in ("x", "X", "b", "o", "x?", "X?") {
      let radix-map = (x: 16, X: 16, "x?": 16, "X?": 16, b: 2, o: 8)
      let radix = radix-map.at(spectype)
      let lowercase = spectype.starts-with("x")
      replacement = _strfmt_stringify(_strfmt_display-radix(replacement, radix, lowercase: lowercase, signed: false))
      if hashtag {
        let hashtag-prefix-map = ("16": "0x", "2": "0b", "8": "0o")
        hashtag-prefix = hashtag-prefix-map.at(str(radix))
      }
    } else {
      precision = none
      replacement = if spectype.ends-with("?") {
        repr(replacement)
      } else {
        _strfmt_stringify(replacement)
      }
    }
    if zero {
      let width-diff = width - (replacement.len() + sign.len() + hashtag-prefix.len())
      if width-diff > 0 {  // prefix with the appropriate amount of zeroes
        replacement = ("0" * width-diff) + replacement
      }
    }
  } else {
    sign = ""
    hashtag-prefix = ""
    hashtag = false
    zero = false
    replacement = if spectype.ends-with("?") {
      repr(replacement)
    } else {
      _strfmt_stringify(replacement)
    }
    if fill == none {
      fill = " "
    }
    if align == none {
      align = left
    }
    if precision != none and replacement.len() > precision {
      replacement = replacement.slice(0, precision)
    }
  }

  // use number prefixes parsed above
  replacement = sign + hashtag-prefix + replacement

  if fill != none {
    // perform fill/width adjustments: "x" ---> "  x" if width is 4
    let width-diff = width - replacement.len()  // number prefixes are also considered for width
    if width-diff > 0 {
      if align == left {
        replacement = replacement + (fill * width-diff)
      } else if align == right {
        replacement = (fill * width-diff) + replacement
      } else if align == center {
        let width-fill = fill * (calc.ceil(float(width-diff) / 2))
        replacement = width-fill + replacement + width-fill
      }
    }
  }

  replacement
}

#let strfmt(format, ..replacements) = {
  let formats = _strfmt_formatparser(format)
  let num-replacements = replacements.pos()
  let named-replacements = replacements.named()
  let unnamed-format-index = 0

  let parts = ()
  let last-span-end = 0
  for f in formats {
    let replace-by = none
    let replace-span = none
    if "escape" in f {
      replace-by = f.escape.escaped
      replace-span = f.escape.span
    } else if "format" in f {
      let f = f.format
      let (name, extras) = _strfmt_parse-fmt-name(f.name)
      if name == none {
        let fmt-index = unnamed-format-index
        if num-replacements.len() <= fmt-index {
          panic("String formatter error: Specified more {} formats than positional replacements.")
        }
        replace-by = num-replacements.at(fmt-index)
        unnamed-format-index += 1
      } else if type(name) == "integer" {
        let fmt-index = name
        if num-replacements.len() <= fmt-index {
          panic("String formatter error: format key '" + name + "', from '{" + f.name + "}', does not match any given positional replacement.")
        }
        replace-by = num-replacements.at(fmt-index)
      } else {  // named replacement
        if name not in named-replacements {
          panic("String formatter error: format key '" + name + "', from '{" + f.name + "}', does not match any given named replacement.")
        }
        replace-by = named-replacements.at(name)
      }
      replace-by = _generate-replacement(f.name, extras, replace-by, pos-replacements: num-replacements, named-replacements: named-replacements)
      replace-span = f.span
    } else {
      panic("String formatter error: Internal error (unexpected format received).")
    }
    // {...}ABCABCABC{...}  <--- push ABCABCABC to parts
    parts.push(format.slice(last-span-end, replace-span.at(0)))
    // push the replacement string instead of {...}
    parts.push(replace-by)
    last-span-end = replace-span.at(1)
  }
  if last-span-end < format.len() {
    parts.push(format.slice(last-span-end, format.len()))
  }

  parts.join()
}
