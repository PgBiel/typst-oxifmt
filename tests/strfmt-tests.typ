#import "../typst-strfmt.typ": strfmt

#{
    // test basics (sequential args, named args, pos args)
    assert.eq(strfmt("a {} b {} c {named} {0} {1}", 10, "tests", named: -24), "a 10 b tests c -24 10 tests")

    // test {:?} (force usage of repr())
    assert.eq(strfmt("a {} c {} d {:?}", true, "testA", "testA"), "a true c testA d \"testA\"")

    // test escaping {{ }}, plus repr() on bools and dicts (and anything that can't be str()'ed)
    assert.eq(strfmt("a{{}}b ={}{}= c{0}d", false, (a: "55", b: 20.3)), "a{}b =false(a: \"55\", b: 20.3)= cfalsed")

    // test 0 prefix with numbers, but also using 0 as a non-numeric affix
    assert.eq(strfmt("{:08}|{0:0<8}|{0:0>8}|{0:0^8}", 120), "00000120|12000000|00000120|000120000")

    // test other kinds of affixes / fills and alignments
    assert.eq(strfmt("{:a>8}, {:^20.10}, {:+05.4}, {}", "b", 5.5, 11, -4), "aaaaaaab,     5.5000000000    , +0011, -4")

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

    // test custom decimal separators
    assert.eq(strfmt("{}; {:07e}; {}; {}; {:?}", 1.532, 45000, -5.6, "a.b", "c.d", fmt-decimal-separator: ","), "1,532; 004,5e4; -5,6; a.b; \"c.d\"")
}
