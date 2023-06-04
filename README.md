# typst-strfmt

A Typst library that brings convenient string formatting and interpolation through the `strfmt` function. Its syntax is taken directly from Rust's `format!` syntax, so read its page for more information (https://doc.rust-lang.org/std/fmt/). Only a few things aren't supported from the Rust syntax, such as the `p` (pointer) format type, or the `.*` precision specifier.

I intend to add a few extras over time, though. The first "extra" I've added so far is the `fmt-decimal-separator: "string"` parameter, which lets you customize the decimal separator for decimal numbers (floats) inserted into strings. E.g. `strfmt("Result: {}", 5.8, fmt-decimal-separator: ",")` will return the string `"Result: 5,8"` (comma instead of dot). See more below.

## Usage

Download the `typst-strfmt.typ` file either from Releases or directly from the repository. Then, move it to your project's folder, and write at the top of your typst file(s):

```js
#import "typst-strfmt.typ": strfmt
```

That will give you access to the main function provided by this library (`strfmt`), which accepts a format string, followed by zero or more replacements to insert in that string (according to `{...}` formats inserted in that string), an optional `fmt-decimal-separator` parameter, and returns the formatted string, as described below.

Its syntax is almost identical to Rust's `format!` (as specified here: https://doc.rust-lang.org/std/fmt/). You can escape formats by duplicating braces (`{{` and `}}` become `{` and `}`). Here are some examples (see more examples in the file `tests/strfmt-tests.typ`):

```js
let s = strfmt("Hi, my name is {}. I have {bananas} bananas. Remember: I am {0}, friend of {}. Braces: {{}}", "John", "Carl", bananas: 10)
assert.eq(s, "Hi, my name is John. I have 10 bananas. Remember: I am John, friend of Carl. Braces: {}")
```

Note that `{}` extracts positional arguments after the string sequentially (the first `{}` extracts the first one, the second `{}` extracts the second one, and so on), while `{0}`, `{1}`, etc. will always extract the first, the second etc. positional arguments after the string. Additionally, `{bananas}` will extract the named argument "bananas".

You can use `{:spec}` to customize your output. See the Rust docs linked above for more info, but here's a summary:

- Adding a `?` at the end of `spec` (that is, writing e.g. `{0:?}`) will call `repr()` to stringify your argument, instead of `str()`. Note that this only has an effect if your argument is a string, an integer, a float or a `label()` / `<label>` - for all other types (such as booleans or elements), `repr()` is always called (as `str()` is unsupported for those).
- After the `:`, add e.g. `_<8` to align the string to the left, padding it with as many `_`s as necessary for it to be at least `8` characters long. Replace `<` by `>` for right alignment, or `^` for center alignment. (If the `_` is omitted, it defaults to ' ' (aligns with spaces).)
    - If you prefer to specify the minimum width (the `8` there) as a separate argument to `strfmt` instead, you can specify `argument$` in place of the width, which will extract it from the integer at `argument`. For example, `_^3$` will center align the output with `_`s, where the minimum width desired is specified by the fourth positional argument (index `3`), as an integer. This means that a call such as `strfmt("{:_^3$}", 1, 2, 3, 4)` would produce `"__1__"`, as `3$` would evaluate to `4` (the value at the fourth positional argument/index `3`). Similarly, `named$` would take the width from the argument with name `named`, if it is an integer (otherwise, error).
- For numbers:
    - Specify `+` after the `:` to ensure zero or positive numbers are prefixed with `+` before them (instead of having no sign). `-` is also accepted but ignored (negative numbers always specify their sign anyways).
    - Use something like `:09` to add zeroes to the left of the number until it has at least 9 digits / characters.
        - The `9` here is also a width, so the same comment from before applies (you can add `$` to take it from an argument to the `strfmt` function).
    - Use `:.5` to ensure your float is represented with 5 decimal digits of precision (zeroes are added to the right if needed; otherwise, it is rounded, **not truncated**).
        - Note that floating point inaccuracies can be sometimes observed here, which is an unfortunate current limitation.
        - Similarly to `width`, the precision can also be specified via an argument with the `$` syntax: `.5$` will take the precision from the integer at argument number 5 (the sixth one), while `.test$` will take it from the argument named `test`.
    - **Integers only:** Add `x` (lowercase hex) or `X` (uppercase) at the end of the `spec` to convert the number to hexadecimal. Also, `b` will convert it to binary, while `o` will convert to octal.
        - Specify a hashtag, e.g. `#x` or `#b`, to prepend the corresponding base prefix to the base-converted number, e.g. `0xABC` instead of `ABC`.
    - Add `e` or `E` at the end of the `spec` to ensure the number is represented in scientific notation (with `e` or `E` as the exponent separator, respectively).
    - For decimal numbers (floats), you can specify `fmt-decimal-separator: ","` to `strfmt` to have the decimal separator be a comma instead of a dot, for example.
        - To have this be the default, you can alias `strfmt`, such as using `#let strfmt = strfmt.with(fmt-decimal-separator: ",")`.
    - Number spec arguments (such as `.5`) are ignored when the argument is not a number, but e.g. a string, even if it looks like a number (such as `"5"`).
- Note that all spec arguments above **have to be specified in order** - if you mix up the order, it won't work properly!
    - Check the grammar below for the proper order, but, in summary: fill (character) with align (`<`, `>` or `^`) -> sign (`+` or `-`) -> `#` -> `0` (for 0 left-padding of numbers) -> width (e.g. `8` from `08` or `9` from `-<9`) -> `.precision` -> spec type (`?`, `x`, `X`, `b`, `o`, `e`, `E`)).

Some examples:

```js
#let s1 = strfmt("{0:?}, {test:+012e}, {1:-<#8x}", "hi", -74, test: 569.4)
#assert.eq(s1, "\"hi\", +00005.694e2, -0x4a---")

#let s2 = strfmt("{:_>+11.5}", 59.4)
#assert.eq(s2, "__+59.40000")

#let s3 = strfmt("Dict: {:!<10?}", (a: 5))
#assert.eq(s3, "Dict: (a: 5)!!!!")
```

## Grammar

Here's the grammar specification for valid format `spec`s (in `{name:spec}`), which is basically Rust's format:

```
format_spec := [[fill]align][sign]['#']['0'][width]['.' precision]type
fill := character
align := '<' | '^' | '>'
sign := '+' | '-'
width := count
precision := count | '*'
type := '' | '?' | 'x?' | 'X?' | identifier
count := parameter | integer
parameter := argument '$'
```

Note, however, that precision of type `.*` is not supported yet and will raise an error.
