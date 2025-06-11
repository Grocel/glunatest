local lunatest = require "lunatest"

function CreateGLunaTestInstance()
	local glunatest = GLunaTestLib:CreateGLunaTestInstance()
	glunatest:AddEmulatorHelper("glunatest/emulatorhelper/gmod.lua")

	return glunatest
end

local CreateGLunaTestInstance = CreateGLunaTestInstance

function test_lunatest_main()
	local glunatest = CreateGLunaTestInstance()
	//glunatest:EnablePrint(false)

	local async = lunatest.async(function(result)
		local buffer = result:getBuffer()

		lunatest.assert_testresult_not_passed(result)
		lunatest.assert_testresult_equal_exitcode(2, result)
		lunatest.assert_testresult_equal_skips(1, result)
		lunatest.assert_testresult_equal_failures(2, result)
		lunatest.assert_testresult_equal_errors(1, result)
		lunatest.assert_testresult_equal_totalerrors(3, result)

		lunatest.assert_match("Error in suite%-hooks%-fail%'s suite_setup%: false", buffer, "suite-hooks-fail error is missing")

		lunatest.assert_match("FAIL%: main%.test_fail %([%d%.ms]+%)%: %(Failed%) %- This one %*should%* fail%. %([%d]+%)", buffer, "fail at main.test_fail is missing")
		lunatest.assert_match("FAIL%: main%.test_failure_formatting %([%d%.ms]+%)%: Expected string to match pattern str with invalid escape %%%( in it%, was str with invalid escape %%%( in %.%.%. %- Should fail but not crash %([%d]+%)", buffer, "fail at main.test_failure_formatting is missing")

		lunatest.assert_match("SKIP%: main%.test_skip%(%) %- %(reason why this test was skipped%)", buffer, "skip at main.test_skip is missing")
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/lunatest/test.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(10)
end

function test_lunatest_error_handler()
	local glunatest = CreateGLunaTestInstance()
	//glunatest:EnablePrint(false)

	local async = lunatest.async(function(result)
		local buffer = result:getBuffer()

		lunatest.assert_testresult_not_passed(result)
		lunatest.assert_testresult_equal_skips(0, result)
		lunatest.assert_testresult_equal_totalerrors(1, result)
		lunatest.assert_testresult_equal_exitcode(1, result)

		lunatest.assert_match("ERROR in test_foo%(%)%:%s*function%:%s*[%w]+", buffer, "error in test_foo() missing")
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/lunatest/test-error_handler.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(10)
end

function test_lunatest_teardown_fail()
	local glunatest = CreateGLunaTestInstance()
	//glunatest:EnablePrint(false)

	local async = lunatest.async(function(result)
		local buffer = result:getBuffer()

		lunatest.assert_testresult_not_passed(result)
		lunatest.assert_testresult_equal_skips(0, result)
		lunatest.assert_testresult_equal_totalerrors(2, result)
		lunatest.assert_testresult_equal_exitcode(2, result)

		lunatest.assert_match("ERROR in teardown handler%:.-%:[%d]+%: %*boom%*", buffer, "'*boom*' error is missing")

		lunatest.assert_match("ERROR in test_fail_but_expect_teardown%(%)%:", buffer, "error in test_fail_but_expect_teardown() is missing")
		lunatest.assert_match("ERROR in test_fail_but_expect_teardown_2%(%)%:", buffer, "error in test_fail_but_expect_teardown_2() is missing")

		lunatest.assert_match("%s*.-%:[%d]+%: fail whale", buffer, "'fail whale' error missing")
		lunatest.assert_match("%s*.-%:[%d]+%: boom", buffer, "'boom' error missing")
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/lunatest/test-teardown_fail.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(10)
end


lunatest.run()
