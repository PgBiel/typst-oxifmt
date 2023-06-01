#let formatparser(s) = {
  if type(s) != "string" {
    panic("String format parser given non-string.")
  }
  let formats = ()
  let escapes = ()
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
  let write-format-span(i, formats, current-fmt-span, current-fmt-name) = {
    current-fmt-span.at(1) = i  // end index
    formats.push((name: current-fmt-name, span: current-fmt-span))
    current-fmt-span = none
    current-fmt-name = none
    (formats, current-fmt-span, current-fmt-name)
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
        escapes.push((escaped: "{", span: (i - 1, i + 1)))
        continue
      }
      if last-was-rbracket {
        // { ... }{ <--- ok, close the previous span
        (formats, current-fmt-span, current-fmt-name) = write-format-span(i, formats, current-fmt-span, current-fmt-name)
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
        escapes.push((escaped: "}", span: (i - 1, i + 1)))
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
          (formats, current-fmt-span, current-fmt-name) = write-format-span(i, formats, current-fmt-span, current-fmt-name)
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
      (formats, current-fmt-span, current-fmt-name) = write-format-span(last-i + 1, formats, current-fmt-span, current-fmt-name)
    } else {
      // {abcd| <--- string ended with unclosed span
      missing-rbracket()
    }
  }

  (formats: formats, escapes: escapes)
}

#let strfmt(format, ..replacements) = {
  let formatted = formatparser(format)
  let formats = formatted.formats
  let escapes = formatted.escapes
  let num-replacements = replacements.pos()
  let named-replacements = replacements.named()
  let unnamed-format-index = 0
  let resulting-string = format

  // when replacing, format indices become outdated
  // this array will keep replacement deltas, keeping 
  // track of string index changes
  let replacement-deltas = ()
  let replace-at(string, span, replacement, deltas) = {
    let start = span.at(0)
    let end = span.at(1)
    if end <= start {
      return (string: string, deltas: deltas)
    }
    let len = end - start
    let replacement-len = replacement.len()
    let strlen = string.len()

    // adjust indices based on deltas
    for delta in deltas {
      let from = delta.from
      let count = delta.count
      if start >= from {
        start += count
        end += count
      }
    }

    let replaced-string = string.slice(0, start) + replacement

    if end < strlen {
      replaced-string += string.slice(end)
    }

    if replacement-len != len {
      deltas.push((from: start + 1, count: replacement-len - len))
    }
    (string: replaced-string, deltas: deltas)
  }

  for f in formats {
    let replace-by = none
    let replace-span = f.span
    if f.name == "" {
      let fmt-index = unnamed-format-index
      if num-replacements.len() <= fmt-index {
        panic("String formatter error: Specified more {} formats than positional replacements.")
      }
      replace-by = str(num-replacements.at(fmt-index))
      unnamed-format-index += 1
    } else if regex("^\\d+$") in f.name {
      let fmt-index = int(f.name)
      if num-replacements.len() <= fmt-index {
        panic("String formatter error: format {" + f.name + "} does not match any given positional replacement.")
      }
      replace-by = str(num-replacements.at(fmt-index))
    } else {  // named replacement
      if f.name not in named-replacements {
        panic("String formatter error: format {" + f.name + "} does not match any given named replacement.")
      }
      replace-by = str(named-replacements.at(f.name))
    }
    let replace-result = replace-at(resulting-string, replace-span, replace-by, replacement-deltas)
    resulting-string = replace-result.string
    replacement-deltas = replace-result.deltas
  }

  for escape in escapes {
    let span = escape.span
    let escaped = escape.escaped
    let replace-result = replace-at(resulting-string, span, escaped, replacement-deltas)
    resulting-string = replace-result.string
    replacement-deltas = replace-result.deltas
  }

  resulting-string
}
