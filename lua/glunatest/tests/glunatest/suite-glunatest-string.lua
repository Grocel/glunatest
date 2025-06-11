local glstring = GLunaTestLib.string
local lunatest = package.loaded.lunatest

local suite = {}

local testtext = "Im a\r\ntext\rwith\nmixed\r\nnewlines\n\rthat could be\n\r\nbroken too"
local testtextn = "Im a\ntext\nwith\nmixed\nnewlines\n\nthat could be\n\nbroken too"

lunatest.add_tests_by_table(suite, "normalizenewlines", {
	{"", ""},
	{testtext, testtextn, "\n"},
	{testtext, "Im a\rtext\rwith\rmixed\rnewlines\r\rthat could be\r\rbroken too", "\r"},
	{testtext, "Im a\r\ntext\r\nwith\r\nmixed\r\nnewlines\r\n\r\nthat could be\r\n\r\nbroken too", "\r\n"},
	{testtext, testtextn},
	{testtext, testtextn, ""},
	{testtext, testtextn, "invalid"},
	{testtext, testtextn, "\n\r"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]
	local nl = data[3]

	local output = glstring:NormalizeNewlines(input, nl)
	lunatest.assert_equal(expected, output)
end)

lunatest.add_tests_by_table(suite, "normalizeslashes", {
	{"", ""},
	{"/path/\\to///file/with/both\\slashtypes\\", "/path/to/file/with/both/slashtypes/"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local output = glstring:NormalizeSlashes(input)
	lunatest.assert_equal(expected, output)
end)

lunatest.add_tests_by_table(suite, "sanitizename", {
	{"", ""},
	{"THISname", "thisname"},
	{"   a NAME with spaces  ", "a_name_with_spaces"},
	{"a NAME with\nnewline", "a_name_with_newline"},
	{"a NAME    with spaces and\ttabs	tabs", "a_name_with_spaces_and_tabs_tabs"},
	{"a dash-NAME with illegal*+~#'chars/\\", "a_dash-name_with_illegal-----chars--"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local output = glstring:SanitizeName(input)
	lunatest.assert_equal(expected, output)
end)

lunatest.add_tests_by_table(suite, "sanitizefunctionname", {
	{"", ""},
	{"THISname", "THISname"},
	{"   a NAME with spaces  ", "a_NAME_with_spaces"},
	{"a NAME with\nnewline", "a_NAME_with_newline"},
	{"a NAME    with spaces and\ttabs	tabs", "a_NAME_with_spaces_and_tabs_tabs"},
	{"a dash-NAME with illegal*+~#'chars/\\", "a_dashNAME_with_illegalchars"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local output = glstring:SanitizeFunctionName(input)
	lunatest.assert_equal(expected, output)
end)

function suite.test_parsetestsummery()
	local summery1 = [[
---- Testing finished in 271.53 ms, with 82 assertion(s) ----
   34 passed, 1 failed, 3 error(s), 5 skipped.
]]

	local summery2 = [[
---- Testing finished in 25.14 s, with 46561 assertion(s) ----
   23157 passed, 544 failed, 210 error(s), 102 skipped.
]]

	local output1 = glstring:ParseTestSummery(summery1)
	lunatest.assert_table(output1)
	lunatest.assert_equal(0.27153, output1.time, 0.0001)
	lunatest.assert_equal(82, output1.assertions)
	lunatest.assert_equal(34, output1.passed)
	lunatest.assert_equal(1, output1.failed)
	lunatest.assert_equal(3, output1.errors)
	lunatest.assert_equal(5, output1.skipped)

	local output2 = glstring:ParseTestSummery(summery2)
	lunatest.assert_table(output2)
	lunatest.assert_equal(25.14, output2.time, 0.01)
	lunatest.assert_equal(46561, output2.assertions)
	lunatest.assert_equal(23157, output2.passed)
	lunatest.assert_equal(544, output2.failed)
	lunatest.assert_equal(210, output2.errors)
	lunatest.assert_equal(102, output2.skipped)
end

function suite.test_getlines()
	local testtext = "Im a\rnewline\r\ntext.\n\nPlease\n\rhelp me..."
	local output = glstring:GetLines(testtext)

	lunatest.assert_equal("Im a",       output[1])
	lunatest.assert_equal("newline",    output[2])
	lunatest.assert_equal("text.",      output[3])
	lunatest.assert_equal("",           output[4])
	lunatest.assert_equal("Please",     output[5])
	lunatest.assert_equal("",           output[6])
	lunatest.assert_equal("help me...", output[7])
end

lunatest.add_tests_by_table(suite, "limitstring", {
	empty = {"", "", 1},
	long = {"a very long text", "a very...", 6},
	short = {"a very short text", "a very short text", 500},
	nodots1 = {"don't add dots yet", "don't add dots yet", 18},
	nodots2 = {"don't add dots yet", "don't add dots yet", 17},
	nodots3 = {"don't add dots yet", "don't add dots yet", 16},
	nodots4 = {"don't add dots yet", "don't add dots yet", 15},
	dots = {"u can add dots now", "u can add dots...", 14},
	utf8_long = {"utf8 test öäüÖÄÜß t", "utf8 test öäüÖÄÜß t", 19},
	utf8_nodots1 = {"utf8 test öäüÖÄÜß t", "utf8 test öäüÖÄÜß t", 18},
	utf8_nodots2 = {"utf8 test öäüÖÄÜß t", "utf8 test öäüÖÄÜß t", 17},
	utf8_nodots3 = {"utf8 test öäüÖÄÜß t", "utf8 test öäüÖÄÜß t", 16},
	utf8_dots1 = {"utf8 test öäüÖÄÜß t", "utf8 test öäüÖÄ...", 15},
	utf8_dots2 = {"utf8 test öäüÖÄÜß t", "utf8 test öäüÖ...", 14},
	utf8_dots3 = {"utf8 test öäüÖÄÜß t", "utf8 test öäü...", 13},
	utf8_dots4 = {"utf8 test öäüÖÄÜß t", "utf8 test öä...", 12},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]
	local limit = data[3]

	local output = glstring:LimitString(input, limit)
	lunatest.assert_equal(expected, output)
end)

function suite.test_replacewhitespace()
	local spacedot = glstring.UTF8_SPACEDOT
	local tabline = glstring.UTF8_TABLINE
	local newlinemarker = glstring.UTF8_NEWLINE_LINUX
	local carriagereturnmarker = glstring.UTF8_NEWLINE_OSX
	local windowsnewlinemarker = glstring.UTF8_NEWLINE_WINDOWS

	local fm = string.format

	local cases = {
		{"", ""},
		{"text with  spaces", fm("text%swith%sspaces", spacedot, spacedot .. spacedot)},
		{"text\twith\t\ttabs", fm("text%swith%stabs", tabline, tabline .. tabline)},
		{"text\rwith\nnewlines", fm("text%s\rwith%s\nnewlines", carriagereturnmarker, newlinemarker)},
		{"text\nwith\n\rother\r\nnewlines", fm(
			"text%s\nwith%s\n%s\rother%s\r\nnewlines",
			newlinemarker,
			newlinemarker,
			carriagereturnmarker,
			windowsnewlinemarker
		)},
	}

	for i, v in ipairs(cases) do
		local input = v[1]
		local expected = v[2]

		local output = glstring:ReplaceWhiteSpace(input)
		lunatest.assert_equal(expected, output, "error at case #" .. i)
	end
end

function suite.test_replacenewlines()
	local newlinemarker = glstring.UTF8_NEWLINE_LINUX
	local carriagereturnmarker = glstring.UTF8_NEWLINE_OSX
	local windowsnewlinemarker = glstring.UTF8_NEWLINE_WINDOWS

	local fm = string.format

	local cases = {
		{"", ""},
		{"text\rwith\nnewlines", fm("text%s\rwith%s\nnewlines", carriagereturnmarker, newlinemarker)},
		{"text\nwith\n\rother\r\nnewlines", fm(
			"text%s\nwith%s\n%s\rother%s\r\nnewlines",
			newlinemarker,
			newlinemarker,
			carriagereturnmarker,
			windowsnewlinemarker
		)},

		{"text\rwith\nnewlines", fm("text%swith%snewlines", carriagereturnmarker, newlinemarker), false},
		{"text\nwith\n\rother\r\nnewlines", fm(
			"text%swith%s%sother%snewlines",
			newlinemarker,
			newlinemarker,
			carriagereturnmarker,
			windowsnewlinemarker
		), false},
	}

	cases[#cases + 1] = {
		cases[2][1], cases[2][2], true
	}

	cases[#cases + 1] = {
		cases[3][1], cases[3][2], true
	}

	for i, v in ipairs(cases) do
		local input = v[1]
		local expected = v[2]
		local keepnl = v[3]

		local output = glstring:ReplaceNewlines(input, keepnl)
		lunatest.assert_equal(expected, output, "error at case #" .. i)
	end
end

function suite.test_trim()
	local spacedot = glstring.UTF8_SPACEDOT
	local tabline = glstring.UTF8_TABLINE
	local newlinemarker = glstring.UTF8_NEWLINE_LINUX
	local carriagereturnmarker = glstring.UTF8_NEWLINE_OSX
	local windowsnewlinemarker = glstring.UTF8_NEWLINE_WINDOWS

	local endstr = spacedot .. tabline .. carriagereturnmarker .. newlinemarker .. carriagereturnmarker .. windowsnewlinemarker
	endstr = endstr .. "\n\r\n\t   \n" .. endstr

	local fm = string.format

	local cases = {
		{"", ""},
		{
			fm("%sA%sB%sC%s", endstr, endstr, endstr, endstr),
			fm("A%sB%sC", endstr, endstr)
		},

	}

	for i, v in ipairs(cases) do
		local input = v[1]
		local expected = v[2]

		local output = glstring:Trim(input)

		lunatest.assert_equal(expected, output, "error at case #" .. i)
	end
end

function suite.test_pattern_escape()
	local input = "test !'\"$ .:,;_- %&/=\\ ()[]{}<> *-+#~@ chars1"
	local expected = "test %!%'%\"%$ %.%:%,%;%_%- %%%&%/%=%\\ %(%)%[%]%{%}%<%> %*%-%+%#%~%@ chars1"

	local output = glstring:PatternEscape(input)
	lunatest.assert_equal(expected, output)

	local reversed = glstring:PatternUnescape(output)
	lunatest.assert_equal(input, reversed)
end

function suite.test_pattern_unescape()
	local input = "test %!%'%\"%$ %.%:%,%;%_%- %%%&%/%=%\\ %(%)%[%]%{%}%<%> %*%-%+%#%~%@ chars2"
	local expected = "test !'\"$ .:,;_- %&/=\\ ()[]{}<> *-+#~@ chars2"

	local output = glstring:PatternUnescape(input)
	lunatest.assert_equal(expected, output)

	local reversed = glstring:PatternEscape(output)
	lunatest.assert_equal(input, reversed)
end


lunatest.add_tests_by_table(suite, "tohex", {
	empty = {"", "", 1},
	plain = {"A Test String", "41205465737420537472696E67"},
	binary = {"\x00\x01\x02\x03\xFD\xFE\xFF", "00010203FDFEFF"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local output = glstring:ToHex(input)
	lunatest.assert_equal(expected, output)
end)

lunatest.add_tests_by_table(suite, "fromhex", {
	empty = {"", "", 1},
	default = {"41205465737420537472696E67010203FDFE", "A Test String\x01\x02\x03\xFD\xFE"},
	lowercase = {"41205465737420537472696e67010203fdfe", "A Test String\x01\x02\x03\xFD\xFE"},
	with_0x = {"0x41205465737420537472696E67010203FDFE", "A Test String\x01\x02\x03\xFD\xFE"},
	with_spaces = {"41205465 73742053 7472696E 67010203 FDFE", "A Test String\x01\x02\x03\xFD\xFE"},
	mixed = {"0X41205465 73742053 7472696E 67010203 fdfe", "A Test String\x01\x02\x03\xFD\xFE"},
	unevenlen = {"123456789", "\x01\x23\x45\x67\x89"},
	binary = {"00010203FDFEFF", "\x00\x01\x02\x03\xFD\xFE\xFF"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local output = glstring:FromHex(input)
	lunatest.assert_equal_bytes(expected, output)
end)

lunatest.add_tests_by_table(suite, "padright", {
	empty = {"", 0, "", ""},
	samelen = {"Test123", 7, " ", "Test123"},
	longer = {"Test123456", 7, " ", "Test123"},
	shorter = {"Test", 7, " ", "Test   "},
	customfill = {"Test", 10, ".", "Test......"},
	zerolen = {"Test", 0, " ", ""},
}, function(key, data, index)
	local input = data[1]
	local len = data[2]
	local fill = data[3]
	local expected = data[4]

	local output = glstring:PadRight(input, len, fill)
	lunatest.assert_equal(expected, output)
end)

lunatest.add_tests_by_table(suite, "padleft", {
	empty = {"", 0, "", ""},
	samelen = {"Test123", 7, " ", "Test123"},
	longer = {"Test123456", 7, " ", "t123456"},
	shorter = {"Test", 7, " ", "   Test"},
	customfill = {"Test", 10, ".", "......Test"},
	zerolen = {"Test", 0, " ", ""},
}, function(key, data, index)
	local input = data[1]
	local len = data[2]
	local fill = data[3]
	local expected = data[4]

	local output = glstring:PadLeft(input, len, fill)
	lunatest.assert_equal(expected, output)
end)

function suite.test_side_by_side()
	local text0 = "   "
	local text1 = "This is a text with newlines\n\n\nto Test SideBySide() 1"
	local text2 = "This is a text with newlines\n\n\n\n\nto Test SideBySide() 2"
	local text3 = "TT 3"

	local expected = [[
    | This is a text with newlines | This is a text with newlines | TT 3
    |                              |                              |
    |                              |                              |
    | to Test SideBySide() 1       |                              |
    |                              |                              |
    |                              | to Test SideBySide() 2       |]]

	local output = glstring:SideBySide(" | ", text0, text1, text2, text3)
	lunatest.assert_equal_ex(expected, output)
end


return suite
