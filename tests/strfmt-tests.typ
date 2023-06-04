#import "../typst-strfmt.typ": strfmt

#{
    assert.eq(strfmt("a {} b {} c {named} {0} {1}", 10, "tests", named: -24), "a 10 b tests c -24 10 tests")
    assert.eq(strfmt("a {} c {} d {:?}", true, "testA", "testA"), "a true c testA d \"testA\"")
    assert.eq(strfmt("a{{}}b ={}{}= c{0}d", false, (a: "55", b: 20.3)), "a{}b =false(a: \"55\", b: 20.3)= cfalsed")
    assert.eq(strfmt("{:08}|{0:0<8}|{0:0>8}|{0:0^8}", 120), "00000120|12000000|00000120|000120000")
    assert.eq(strfmt("{:a>8}, {:^20.10}, {:+05.4}, {}", "b", 5.5, 11, -4), "aaaaaaab,     5.5000000000    , +0011, -4")
    assert.eq(strfmt("{:b}, {0:05b}, {:#010b}, {:05x}, {:05X}, {:+#05X}, {2:x?}, {3:X?}", 5, 5, 27, 27, 27), "101, 00101, 0b00000101, 0001b, 0001B, +0x1B, 1b, 1B")
    assert.eq(strfmt("{:x}, {:X}, {:#X}, {:#X}, {:o}, {:#o}", 259, 259, 259, -259, 66, 66), "103, 103, 0x103, -0x103, 102, 0o102")
    assert.eq(strfmt("{:-^+#10b}, {fl:+08}", 5, fl: 55.43), "--+0b101--, +0055.43")
    assert.eq(strfmt("{:e}, {:.7E}, {:e}, {:010.2E}, {:+e}", 4213.4, 521.32947, 0.0241, -0.00432, 190000), "4.2134e3, 5.2132947E2, 2.41e-2, -004.32E-3, +1.9e5")
}
