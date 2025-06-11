local gljson = GLunaTestLib.json
local glstring = GLunaTestLib.string
local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_mock_global_function()
	local mock = lunatest.mock_global_function("net.WriteInt")

	local expectedR1 = "im a mock1"
	local expectedR2 = "im a mock2"

	mock:Callback(function(this, a, b)
		lunatest.assert_equal(155, a)
		lunatest.assert_equal(122, b)

		return expectedR1
	end)

	local gotR1 = net.WriteInt(155, 122)

	mock:Callback(function(this, a, b)
		lunatest.assert_equal(255, a)
		lunatest.assert_equal(222, b)

		return expectedR2, "X"
	end)

	local gotR2, X = net.WriteInt(255, 222)

	lunatest.assert_equal(expectedR1, gotR1)
	lunatest.assert_equal(expectedR2, gotR2)
	lunatest.assert_equal("X", X)

	lunatest.assert_equal(2, mock:GetCalled())
end

function suite.test_mock_global_function_name_as_table()
	local mock = lunatest.mock_global_function({"net", "WriteInt"})

	local expectedR1 = "im a mock1"
	local expectedR2 = "im a mock2"

	mock:Callback(function(this, a, b)
		lunatest.assert_equal(155, a)
		lunatest.assert_equal(122, b)

		return expectedR1
	end)

	local gotR1 = net.WriteInt(155, 122)

	mock:Callback(function(this, a, b)
		lunatest.assert_equal(255, a)
		lunatest.assert_equal(222, b)

		return expectedR2, "X"
	end)

	local gotR2, X = net.WriteInt(255, 222)

	lunatest.assert_equal(expectedR1, gotR1)
	lunatest.assert_equal(expectedR2, gotR2)
	lunatest.assert_equal("X", X)

	lunatest.assert_equal(2, mock:GetCalled())
end

function suite.test_mock_global_function_error_callback()
	local mock = lunatest.mock_global_function("net.WriteInt")

	mock:Callback(function(this)
		error("im broken")
	end)

	lunatest.assert_error(function()
		net.WriteInt()
	end)
end

function suite.test_mock_global_function_blacklisted_functions()
	lunatest.assert_error(function()
		lunatest.mock_global_function("error")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("Error")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("ErrorNoHalt")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("print")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("Msg")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("rawequal")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("_G.rawequal")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("_G._G.rawequal")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("debug.Trace")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("_G.debug.Trace")
	end)

	lunatest.assert_error(function()
		lunatest.mock_global_function("_G._G.debug.Trace")
	end)
end

function suite.test_mock_global_function_cleanup()
	local mock = lunatest.mock_global_function("math.log10")

	mock:Callback(function(this, a)
		return "im a mock " .. a
	end)

	lunatest.assert_equal("im a mock 1000", math.log10(1000))
	lunatest.assert_equal("im a mock 10", math.log10(10))

	mock:Remove()

	lunatest.assert_equal(3, math.log10(1000))
	lunatest.assert_equal(1, math.log10(10))
end

return suite
