local lunatest = require "lunatest"

lunatest.suite("glunatest/suite-glunatest-simplediff")

lunatest.suite("glunatest/suite-glunatest")
lunatest.suite("glunatest/suite-setup")

lunatest.suite("glunatest/suite-glunatest-string")
lunatest.suite("glunatest/suite-glunatest-table")
lunatest.suite("glunatest/suite-glunatest-coroutine")
lunatest.suite("glunatest/suite-glunatest-print")
lunatest.suite("glunatest/suite-glunatest-file")
lunatest.suite("glunatest/suite-glunatest-json")
lunatest.suite("glunatest/suite-glunatest-config")
lunatest.suite("glunatest/suite-glunatest-mock")

function test_assert_text_equal()
	local text1 = [[
	Hello, I'm a multiline text.
	I also have tabs inside.
]]

	local text2 = [[
	Hello, I'm a multiline text.
	I also have tabs inside.
]]
	lunatest.assert_equal_ex(text1, text2)
end

function test_assert_table_equal()

	local A = {
		["key with\tmultilines\n\r\ntest"] = "value with\tmultilines\n\n\rtest",
		"other value",
	}

	A.nested = A
	A[A] = A

	local B = {
		["key with\tmultilines\n\r\ntest"] = "value with\tmultilines\n\n\rtest",
		"other value",
	}

	B.nested = B
	B[B] = B

	lunatest.assert_equal_ex(A, B)
end

function test_assert_text_not_equal()
	local text1 = [[
	Hello, I'm a multiline text.
	I also have tabs inside.
]]

	local text2 = [[
	Hello, I'm a multiline text.
	I also have tabs inside.
	(Changed)
]]
	lunatest.assert_not_equal_ex(text1, text2)
end

function test_assert_table_not_equal()

	local A = {
		["key with\tmultilines\n\r\ntest"] = "value with\tmultilines\n\n\rtest",
		"other value",
	}

	A.nested = A
	A[A] = A

	local B = {
		["key with\tmultilines\n\r\ntest"] = "value with\tmultilines\n\n\rtest",
		"other value",
		"(Changed)",
	}

	B.nested = B
	B[B] = B

	lunatest.assert_not_equal_ex(A, B)
end

lunatest.run()
