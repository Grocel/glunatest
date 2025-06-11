local lunatest = require "lunatest"
local glcoroutine = GLunaTestLib.coroutine

local timefactor = 0.250

function test_async_timer_error()
	local async = lunatest.async(function()
		lunatest.fail("This one *should* fail.")
	end)

	timer.Simple(timefactor, -async)

	async:Sync(timefactor * 4)

	error("not failed")
end

function test_async_timer_nestedA_error()
	local async = lunatest.async(function()
		lunatest.fail("This one *should* fail.")
	end)

	timer.Simple(timefactor, function()
		timer.Simple(timefactor, function()
			timer.Simple(timefactor, -async)
		end)
	end)

	async:Sync(timefactor * 6)

	error("not failed")
end

function test_async_timer_nestedB_error()
	local async2 = nil

	local async = lunatest.async(function()
		lunatest.assert_true(true)

		async2 = lunatest.async(function()
			lunatest.fail("This one *should* fail.")
		end)

		timer.Simple(timefactor, -async2)
	end)

	timer.Simple(timefactor, -async)

	async:Sync(timefactor * 6)
	async2:Sync(timefactor * 3)

	error("not failed")
end

function test_async_timeout_error()
	local async = lunatest.async(function()
		lunatest.fail("Timeout error failed.")
	end)

	timer.Simple(timefactor * 10, -async)

	async:Sync(timefactor)

	error("not failed")
end

lunatest.run()
