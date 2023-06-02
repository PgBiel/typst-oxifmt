#import "../typst-strfmt.typ": strfmt

#{
    assert.eq(strfmt("a {} b {} c {named} {0} {1}", 10, "tests", named: -24), "a 10 b tests c -24 10 tests")
    assert.eq(strfmt("a {} c {} d {:?}", true, "testA", "testA"), "a true c testA d \"testA\"")
    assert.eq(strfmt("a{{}}b ={}{}= c{0}d", false, (a: "55", b: 20.3)), "a{}b =false(a: \"55\", b: 20.3)= cfalsed")
    assert.eq(strfmt("{:08}|{0:<08}|{0:>08}|{0:^08}", 120), "00000120|12000000|00000120|000120000")
    assert.eq(strfmt("{:a>8}, {:^20.10}", "b", 5.5), "aaaaaaab,     5.5000000000    ")
}
