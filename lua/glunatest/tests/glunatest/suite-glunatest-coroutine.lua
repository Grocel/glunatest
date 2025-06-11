local glcoroutine = GLunaTestLib.coroutine
local lunatest = package.loaded.lunatest

local suite = {}
local timefactor = 0.250

function suite.test_async_timer()
	local done = false

	local async = lunatest.async(function()
		lunatest.assert_true(true)
		done = true
	end)

	timer.Simple(timefactor, -async)

	async:Sync(timefactor * 3)

	lunatest.assert_true(done)
end

function suite.test_async_timer_nestedA()
	local done = false

	local async = lunatest.async(function()
		lunatest.assert_true(true)
		done = true
	end)

	timer.Simple(timefactor, function()
		timer.Simple(timefactor, -async)
	end)

	async:Sync(timefactor * 6)
	lunatest.assert_true(done)
end

function suite.test_async_timer_nestedB()
	local done = false

	local async2 = nil

	local async = lunatest.async(function()
		lunatest.assert_true(true)

		local done2 = false
		async2 = lunatest.async(function()
			lunatest.assert_true(true)
			done = true
		end)

		timer.Simple(timefactor, -async2)
	end)

	timer.Simple(timefactor, -async)

	async:Sync(timefactor * 6)
	async2:Sync(timefactor * 3)

	lunatest.assert_true(done)
end

function CreateGLunaTestInstance()
	local glunatest = GLunaTestLib:CreateGLunaTestInstance()
	glunatest:AddEmulatorHelper("glunatest/emulatorhelper/gmod.lua")

	return glunatest
end

local CreateGLunaTestInstance = CreateGLunaTestInstance

function suite.test_error_cases()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(true)

	local async = lunatest.async(function(result)
		local buffer = result:getBuffer()

		lunatest.assert_testresult_not_passed(result)
		lunatest.assert_testresult_equal_exitcode(4, result)
		lunatest.assert_testresult_equal_skips(0, result)
		lunatest.assert_testresult_equal_failures(3, result)
		lunatest.assert_testresult_equal_errors(1, result)
		lunatest.assert_testresult_equal_totalerrors(4, result)

		lunatest.assert_match("FAIL%: main%.test_async_timer_error %([%d%.ms]+%)%: %(Failed%) %- This one %*should%* fail%. %([%d]+%)", buffer, "fail at main.test_async_timer_error is missing")
		lunatest.assert_match("FAIL%: main%.test_async_timer_nestedA_error %([%d%.ms]+%)%: %(Failed%) %- This one %*should%* fail%. %([%d]+%)", buffer, "fail at main.test_async_timer_nestedA_error is missing")
		lunatest.assert_match("FAIL%: main%.test_async_timer_nestedB_error %([%d%.ms]+%)%: %(Failed%) %- This one %*should%* fail%. %([%d]+%)", buffer, "fail at main.test_async_timer_nestedB_error is missing")

		lunatest.assert_match("ERROR in test_async_timeout_error%(%)%:%s*.-%:[%d]+%: Awaited condition did not occur within the set time.", buffer, "error in test_async_timeout_error() missing")
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-glunatest-coroutine-errorcases.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(30)
end

return suite
