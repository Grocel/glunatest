local lunatest = require "lunatest"

local CreateGLunaTestInstance = CreateGLunaTestInstance

function test_nested_glunatest_instance()
	lunatest.assert_table(GLunaTestLib)

	local glunatest = GLunaTestLib:CreateGLunaTestInstance()
	lunatest.assert_table(glunatest)
end

function test_nested_testing()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(lunatest.ISASYNCHRONOUS)

	lunatest.assert_equal(lunatest.ISASYNCHRONOUS, glunatest:IsAsynchronous())

	if lunatest.TESTLEVEL > 7 then
		lunatest.assert_true(true)
		return
	end

	local async = lunatest.async(function(result)
		lunatest.assert_testresult_passed(result)
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-nested.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(20)
end

lunatest.run()
