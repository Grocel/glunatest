local glstring = GLunaTestLib.string
local lunatest = package.loaded.lunatest

local suite = {}

lunatest.add_tests_by_table(suite, "processdiffresult", {
	empty = {
		diff = {
			A = "",
			B = "",
		},
		options = {},
		results = {
			differences = "",
			errordiffblocks = 0,
			errordiffhiddenblocks = 0,
		},
	},
	text = {
		diff = {
			A = [[
	Hello, I'm a multiline text.
	I also have tabs inside.

	a
	b
	c
	d

	fff











		xx










	sss
	www

	awdaaw
	awdawds

	aw



	aa
	aa

	aa
	aa

	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa






	xx
]],
			B = [[
	Hello, I'm a multiline text.
	I also have tabs inside.

	a
	b
	c
	d

	fff











	xx3










	sss
	sss
	www

	awdaaw
	awdawds

	awx



	aa
	aa

	aa
	aa

	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa
	aa







]],
		},
		options = {},
		results = {
			differences = [[
    21 -\t\txx
    21 +\txx3

     ...

    32  \tsss
    33 +\tsss
    34  \twww
    35\s\s
    36  \tawdaaw
    37  \tawdawds
    38\s\s
    39 -\taw
    39 +\tawx
    40\s\s
    41\s\s
    42\s\s
    43  \taa
    44  \taa
    45\s\s
    46  \taa
    47  \taa
    48\s\s
    49  \taa

     ...

    66 -\txx

     ...

    68 +

  5 difference blocks found
]],
			errordiffblocks = 5,
			errordiffhiddenblocks = 0,
		},
	},
	skippedoutput = {
		diff = {
			A = [[
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
]],
			B = [[
1
2x
3x
4
5
6
7
8
9
10x
11x
12x
13x
14
15
16
17x
18x
19
20
]],
		},
		options = {
			maxdiffblocks = 2,
			maxdiffsize = 4,
		},
		results = {
			differences = [[
     1  1
     2 -2
     3 -3
     2 +2x
     3 +3x
     4  4
     5  5
     6  6
     7  7
     8  8
     9  9
       - 4 lines starting at line 10
       + 4 lines starting at line 10

     ...

    14  14
    15  15
    16  16

     ...

  3 difference blocks found (1 hidden)
]],
			errordiffblocks = 3,
			errordiffhiddenblocks = 1,
		},
	},
}, function(key, data, index)
	local diff = GLunaTestLib.string:Diff(data.diff.A, data.diff.B)
	local differences, errordiffblocks, errordiffhiddenblocks = GLunaTestLib.print:ProcessDiffResult(diff, data.options)
	local expectedresults = data.results

	local gotDifferences = string.Trim(differences)
	local expDifferences = string.Trim(expectedresults.differences)

	expDifferences = string.Replace(expDifferences, "\\t", "\t")
	expDifferences = string.Replace(expDifferences, "\\s", " ")

	lunatest.assert_equal(expectedresults.errordiffblocks, errordiffblocks)
	lunatest.assert_equal(expectedresults.errordiffhiddenblocks, errordiffhiddenblocks)
	lunatest.assert_equal_ex(expDifferences, gotDifferences)
	lunatest.assert_equal(expDifferences, gotDifferences)
end)

lunatest.add_tests_by_table(suite, "processequalresult", {
	empty = {
		input = "",
		options = {},
		results = {
			summary = "",
			skippedlines = 0,
		},
	},
	text = {
		input = [[x1
x2
	a1
	a2
		b1
x3
x4
	a1
x5
]],
		options = {},
		results = {
			summary = [[
     1  x1
     2  x2
     3  \ta1
     4  \ta2
     5  \t\tb1
     6  x3
     7  x4
     8  \ta1
     9  x5
    10
]],
			skippedlines = 0,
		},
	},
	skippedoutput1 = {
		input = [[
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
]],
		options = {
			maxstartlines = 6,
			maxendlines = 4,
		},
		results = {
			summary = [[
	 1  1
     2  2
     3  3
     4  4
     5  5
     6  6

         11 lines hidden starting at line 7

    18  18
    19  19
    20  20
    21
]],
			skippedlines = 11,
		},
	},
	skippedoutput2 = {
		input = [[
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
]],
		options = {
			maxstartlines = 6,
			maxendlines = 0,
		},
		results = {
			summary = [[
	 1  1
     2  2
     3  3
     4  4
     5  5
     6  6

         15 lines hidden starting at line 7
]],
			skippedlines = 15,
		},
	},
	skippedoutput3 = {
		input = [[
1
2
3
4
5
6
7
8
9
10
11
12
13
14
15
16
17
18
19
20
]],
		options = {
			maxstartlines = 0,
			maxendlines = 4,
		},
		results = {
			summary = [[
         17 lines hidden starting at line 1

    18  18
    19  19
    20  20
    21
]],
			skippedlines = 17,
		},
	},
}, function(key, data, index)
	local summary, skippedlines = GLunaTestLib.print:ProcessEqualResult(data.input, data.options)
	local expectedresults = data.results

	local gotSummary = string.Trim(summary)
	local expSummary = string.Trim(expectedresults.summary)

	expSummary = string.Replace(expSummary, "\\t", "\t")
	expSummary = string.Replace(expSummary, "\\s", " ")

	lunatest.assert_equal(expectedresults.skippedlines, skippedlines)
	lunatest.assert_equal_ex(expSummary, gotSummary)
	lunatest.assert_equal(expSummary, gotSummary)
end)

lunatest.add_tests_by_table(suite, "processdiffresultlegend", {
	empty1 = {
		input = "",
		prefix = "",
		result = "",
	},
	empty2 = {
		input = "",
		prefix = "Prefix",
		result = [[
      Prefix
]],
	},
	empty3 = {
		input = "x",
		prefix = "Prefix",
		result = [[
      Prefix
]],
	},
	empty4 = {
		input = "",
		prefix = "\n\n\n\n",
		result = "",
	},
	empty5 = {
		input = "x",
		prefix = "\n\n\n\n",
		result = "",
	},
	empty6 = {
		input = "",
		prefix = "Prefix\nPrefix2",
		result = [[
      Prefix
      Prefix2
]],
	},
	empty7 = {
		input = "x",
		prefix = "Prefix\nPrefix2",
		result = [[
      Prefix
      Prefix2
]],
	},
	null = {
		input = "\x00",
		prefix = "",
		result = [[
      Whitespaces:  %s NULL (\0)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NULLBYTE,
		},
	},
	space1 = {
		input = " ",
		prefix = "",
		result = [[
      Whitespaces:  %s Space ( )
]],
		resultdata = {
			GLunaTestLib.string.UTF8_SPACEDOT,
		},
	},
	space2 = {
		input = " ",
		prefix = "\n\n\n\n",
		result = [[
      Whitespaces:  %s Space ( )
]],
		resultdata = {
			GLunaTestLib.string.UTF8_SPACEDOT,
		},
	},
	space3 = {
		input = " ",
		prefix = "Prefix 1 line",
		result = [[
      Prefix 1 line        Whitespaces:  %s Space ( )
]],
		resultdata = {
			GLunaTestLib.string.UTF8_SPACEDOT,
		},
	},
	space4 = {
		input = " ",
		prefix = "Prefix 1 line\nPrefix 2 line",
		result = [[
      Prefix 1 line        Whitespaces:  %s Space ( )
      Prefix 2 line
]],
		resultdata = {
			GLunaTestLib.string.UTF8_SPACEDOT,
		},
	},
	tab = {
		input = "x\tx",
		prefix = "",
		result = [[
      Whitespaces:  %s Tab (\t)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_TABLINE,
		},
	},
	newline_r = {
		input = "x\rx",
		prefix = "",
		result = [[
      Whitespaces:  %s CR (\r)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
		},
	},
	newline_n = {
		input = "x\nx",
		prefix = "",
		result = [[
      Whitespaces:  %s LF (\n)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
		},
	},
	newline_rn = {
		input = "x\r\nx",
		prefix = "",
		result = [[
      Whitespaces:  %s LF (\n)  %s CRLF (\r\n)
                    %s CR (\r)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_WINDOWS,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
		},
	},
	newline_nr = {
		input = "x\n\rx",
		prefix = "",
		result = [[
      Whitespaces:  %s LF (\n)
                    %s CR (\r)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
		},
	},
	newline_all1 = {
		input = "1 2\t3\n4\r5\r\n6",
		prefix = "",
		result = [[
      Whitespaces:  %s LF (\n)  %s   CRLF (\r\n)  %s Space ( )
                    %s CR (\r)  %s Tab  (\t)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_WINDOWS,
			GLunaTestLib.string.UTF8_SPACEDOT,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
			GLunaTestLib.string.UTF8_TABLINE,
		},
	},
	newline_all2 = {
		input = "1 2\t3\n4\r5\r\n6",
		prefix = "Prefix 1234",
		result = [[
      Prefix 1234        Whitespaces:  %s LF (\n)  %s   CRLF (\r\n)  %s Space ( )
                                       %s CR (\r)  %s Tab  (\t)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_WINDOWS,
			GLunaTestLib.string.UTF8_SPACEDOT,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
			GLunaTestLib.string.UTF8_TABLINE,
		},
	},
	newline_all3 = {
		input = "1 2\t3\n4\r5\r\n6",
		prefix = "Prefix 1234\nPrefix 5678",
		result = [[
      Prefix 1234        Whitespaces:  %s LF (\n)  %s   CRLF (\r\n)  %s Space ( )
      Prefix 5678                      %s CR (\r)  %s Tab  (\t)
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_WINDOWS,
			GLunaTestLib.string.UTF8_SPACEDOT,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
			GLunaTestLib.string.UTF8_TABLINE,
		},
	},
	newline_all4 = {
		input = "1 2\t3\n4\r5\r\n6",
		prefix = "Prefix 0123\nPrefix 4567\nPrefix 89AB\nPrefix CDEF",
		result = [[
      Prefix 0123        Whitespaces:  %s LF (\n)  %s   CRLF (\r\n)  %s Space ( )
      Prefix 4567                      %s CR (\r)  %s Tab  (\t)
      Prefix 89AB
      Prefix CDEF
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_WINDOWS,
			GLunaTestLib.string.UTF8_SPACEDOT,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
			GLunaTestLib.string.UTF8_TABLINE,
		},
	},

	newline_all5 = {
		input = "1 2\t3\n4\r5\r\n6\x00 7",
		prefix = "Prefix 0123\nPrefix 4567\nPrefix 89AB\nPrefix CDEF",
		result = [[
      Prefix 0123        Whitespaces:  %s LF (\n)  %s   CRLF (\r\n)  %s Space ( )
      Prefix 4567                      %s CR (\r)  %s Tab  (\t)    %s NULL  (\0)
      Prefix 89AB
      Prefix CDEF
]],
		resultdata = {
			GLunaTestLib.string.UTF8_NEWLINE_LINUX,
			GLunaTestLib.string.UTF8_NEWLINE_WINDOWS,
			GLunaTestLib.string.UTF8_SPACEDOT,
			GLunaTestLib.string.UTF8_NEWLINE_OSX,
			GLunaTestLib.string.UTF8_TABLINE,
			GLunaTestLib.string.UTF8_NULLBYTE,
		},
	},
}, function(key, data, index)
	local input = GLunaTestLib.string:ReplaceWhiteSpace(data.input)
	local gotResult = GLunaTestLib.print:ProcessDiffResultLegend(input, data.prefix)
	local expResult = data.result

	gotResult = string.Trim(gotResult)

	expResult = string.Replace(expResult, "\\s", " ")
	expResult = string.format(expResult, unpack(data.resultdata or {}))
	expResult = string.Trim(expResult)

	lunatest.assert_equal_ex(expResult, gotResult)
	lunatest.assert_equal(expResult, gotResult)
end)


return suite
