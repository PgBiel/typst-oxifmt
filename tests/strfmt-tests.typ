#import "../typst-oxifmt.typ": strfmt

#{
    // test basics (sequential args, named args, pos args)
    assert.eq(strfmt("a {} b {} c {named} {0} {1}", 10, "tests", named: -24), "a 10 b tests c -24 10 tests")

    // test {:?} (force usage of repr())
    assert.eq(strfmt("a {} c {} d {:?}", true, "testA", "testA"), "a true c testA d \"testA\"")

    // test escaping {{ }}, plus repr() on bools and dicts (and anything that can't be str()'ed)
    assert.eq(strfmt("a{{}}b ={}{}= c{0}d", false, (a: "55", b: 20.3)), "a{}b =false(a: \"55\", b: 20.3)= cfalsed")

    // test escaping {{ }} from inside { } formats
    assert.eq(strfmt("a{b{{b}}b}", ..("b{b}b": 5)), "a5")

    // test 0 prefix with numbers, but also using 0 as a non-numeric affix
    assert.eq(strfmt("{:08}|{0:0<8}|{0:0>8}|{0:0^8}", 120), "00000120|12000000|00000120|000120000")

    // test other kinds of affixes / fills and alignments
    assert.eq(strfmt("{:a>8}, {:^20.10}, {:+05.4}, {:07}, {other:06?}", "b", 5.5, 11, -4, other: -30.0), "aaaaaaab,     5.5000000000    , +0011, -000004, -030.0")

    // test base conversion (I)
    assert.eq(strfmt("{:b}, {0:05b}, {:#010b}, {:05x}, {:05X}, {:+#05X}, {2:x?}, {3:X?}", 5, 5, 27, 27, 27), "101, 00101, 0b00000101, 0001b, 0001B, +0x1B, 1b, 1B")

    // test base conversion (II)
    assert.eq(strfmt("{:x}, {:X}, {:#X}, {:#X}, {:o}, {:#o}", 259, 259, 259, -259, 66, 66), "103, 103, 0x103, -0x103, 102, 0o102")

    // some numeric tests with affixes and stuff
    assert.eq(strfmt("{:-^+#10b}, {fl:+08}", 5, fl: 55.43), "--+0b101--, +0055.43")

    // test scientific notation
    assert.eq(strfmt("{:e}, {:.7E}, {:e}, {:010.2E}, {:+e}", 4213.4, 521.32947, 0.0241, -0.00432, 190000), "4.2134e3, 5.2132947E2, 2.41e-2, -004.32E-3, +1.9e5")

    // test taking width and precision from pos args / named args (.x$ / y$ notation)
    assert.eq(strfmt("{:.1$}; {woah:0france$.moment$}; {}; {2:a>1$}", 5.5399234, 9, "stringy", woah: 3.9, france: 7, moment: 2), "5.539923400; 0003.90; 9; aastringy")

    // test weird precision cases
    assert.eq(strfmt("{0:e} {0:+.9E} | {1:.3e} {1:.3} {2:.3} | {3:.4} {3:.4E} | {4:.2} {4:.3} {4:.5}", 124.2312, 50, 50.0, -0.02, 2.44454), "1.242312e2 +1.242312000E2 | 5.000e1 50 50.000 | -0.0200 -2.0000E-2 | 2.44 2.445 2.44454")

    // test custom decimal separators (I)
    assert.eq(strfmt("{}; {:07e}; {}; {}; {:?}", 1.532, 45000, -5.6, "a.b", "c.d", fmt-decimal-separator: ","), "1,532; 004,5e4; -5,6; a.b; \"c.d\"")

    // test custom decimal separators (II) - weird values
    assert.eq(strfmt("{}; {:015e}; {}; {}; {:?}", 1.532, 45000, -5.6, "a.b", "c.d", fmt-decimal-separator: (a: 5)), "1(a: 5)532; 000004(a: 5)5e4; -5(a: 5)6; a.b; \"c.d\"")

    // test custom decimal separators (III) - ensure we can fetch it from inside
    assert.eq(strfmt("5{fmt-decimal-separator}6", fmt-decimal-separator: "|"), "5|6")
}
// DOC TESTS
#{
    // --- Usage ---
    {
        let s = strfmt("I'm {}. I have {num} cars. I'm {0}. {} is {{cool}}.", "John", "Carl", num: 10)
        assert.eq(s, "I'm John. I have 10 cars. I'm John. Carl is {cool}.")
    }
    // --- Formatting options ---
    {
        let s1 = strfmt("{0:?}, {test:+012e}, {1:-<#8x}", "hi", -74, test: 569.4)
        assert.eq(s1, "\"hi\", +00005.694e2, -0x4a---")

        let s2 = strfmt("{:_>+11.5}", 59.4)
        assert.eq(s2, "__+59.40000")

        let s3 = strfmt("Dict: {:!<10?}", (a: 5))
        assert.eq(s3, "Dict: (a: 5)!!!!")
    }
    // --- Examples ---
    {
        let s = strfmt("First: {}, Second: {}, Fourth: {3}, Banana: {banana} (brackets: {{escaped}})", 1, 2.1, 3, label("four"), banana: "Banana!!")
        assert.eq(s, "First: 1, Second: 2.1, Fourth: four, Banana: Banana!! (brackets: {escaped})")
    }
    {
        let s = strfmt("The value is: {:?} | Also the label is {:?}", "something", label("label"))
        assert.eq(s, "The value is: \"something\" | Also the label is <label>")
    }
    {
        let s = strfmt("Values: {:?}, {1:?}, {stuff:?}", (test: 500), ("a", 5.1), stuff: [a])
        assert.eq(s, "Values: (test: 500), (\"a\", 5.1), [a]")
    }
    {
        let s = strfmt("Left5 {:_<5}, Right6 {:*>6}, Center10 {centered: ^10?}, Left3 {tleft:_<3}", "xx", 539, tleft: "okay", centered: [a])
        assert.eq(s, "Left5 xx___, Right6 ***539, Center10     [a]    , Left3 okay")
    }
    {
        let s = strfmt("Left-padded7 numbers: {:07} {:07} {:07} {3:07}", 123, -344, 44224059, 45.32)
        assert.eq(s, "Left-padded7 numbers: 0000123 -000344 44224059 0045.32")
    }
    {
        let s = strfmt("Some numbers: {:+} {:+08}; With fill and align: {:_<+8}; Negative (no-op): {neg:+}", 123, 456, 4444, neg: -435)
        assert.eq(s, "Some numbers: +123 +0000456; With fill and align: +4444___; Negative (no-op): -435")
    }
    {
        let s = strfmt("Bases (10, 2, 8, 16(l), 16(U):) {0} {0:b} {0:o} {0:x} {0:X} | W/ prefixes and modifiers: {0:#b} {0:+#09o} {0:_>+#9X}", 124)
        assert.eq(s, "Bases (10, 2, 8, 16(l), 16(U):) 124 1111100 174 7c 7C | W/ prefixes and modifiers: 0b1111100 +0o000174 ____+0x7C")
    }
    {
        let s = strfmt("{0:.8} {0:.2$} {0:.potato$}", 1.234, 0, 2, potato: 5)
        assert.eq(s, "1.23400000 1.23 1.23400")
    }
    {
        let s = strfmt("{0:e} {0:E} {0:+.9e} | {1:e} | {2:E}", 124.2312, 50, -0.02)
        assert.eq(s, "1.242312e2 1.242312E2 +1.242312000e2 | 5e1 | -2E-2")
    }
    {
        let s = strfmt("{0} {0:.6} {0:.5e}", 1.432, fmt-decimal-separator: ",")
        assert.eq(s, "1,432 1,432000 1,43200e0")
    }
}
