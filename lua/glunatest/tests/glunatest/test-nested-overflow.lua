local lunatest = require "lunatest"

local CreateGLunaTestInstance = CreateGLunaTestInstance

function test_nested_glunatest_instance()
	lunatest.assert_table(GLunaTestLib)

	local glunatest = GLunaTestLib:CreateGLunaTestInstance()
	lunatest.assert_table(glunatest)
end

function test_nested_testingoverflow()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(lunatest.ISASYNCHRONOUS)

	lunatest.assert_equal(lunatest.ISASYNCHRONOUS, glunatest:IsAsynchronous())

	if (lunatest.TESTLEVEL > GLunaTestLib:GetMaxNestedTestLevel() + 3) then
		lunatest.fail("nesting overflow protection failed")
		return
	end

	local async = lunatest.async(function(result)
		local buffer = result:getBuffer()

		if (result:hasPassedStrict()) then
			lunatest.assert_testresult_passed(result)
			return
		end

		lunatest.assert_testresult_equal_failures(0, result)
		lunatest.assert_testresult_equal_errors(1, result)
		lunatest.assert_testresult_equal_totalerrors(1, result)
		lunatest.assert_testresult_equal_exitcode(1, result)

		lunatest.assert_match("ERROR in test_nested_testingoverflow%(%)%:%s*.-%:[%d]+%: nested test stack overflow", buffer, "error in test_nested_testingoverflow() has unexpected content")
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-nested-overflow.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(20)
end

lunatest.run()
