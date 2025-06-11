local simplediff = GLunaTestLib.simplediff
local lunatest = package.loaded.lunatest

function CreateGLunaTestInstance()
	local glunatest = GLunaTestLib:CreateGLunaTestInstance()
	glunatest:AddEmulatorHelper("glunatest/emulatorhelper/gmod.lua")

	return glunatest
end

local CreateGLunaTestInstance = CreateGLunaTestInstance

local suite = {}

function suite.test_testlevel()
	lunatest.assert_equal(1, lunatest.TESTLEVEL)
end

function suite.test_instance()
	lunatest.assert_table(GLunaTestLib)
	lunatest.assert_function(GLunaTestLib.CreateGLunaTestInstance)

	local glunatestsetup = GLunaTestLib:CreateGLunaTestInstance()
	lunatest.assert_table(glunatestsetup)
end

function suite.test_global_pollute()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)

	table.someglobal1 = "table.someglobal1"
	_G.someglobal1 = "_G.someglobal1"
	someglobal2 = "someglobal2"

	table.dontchangemeglobal1 = "table.dontchangemeglobal1"
	_G.dontchangemeglobal1 = "_G.dontchangemeglobal1"
	dontchangemeglobal2 = "dontchangemeglobal2"

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-global-pollute.lua", nil, nil, function(result)
		lunatest.assert_function(table.Copy)
		lunatest.assert_function(_G.table.Copy)

		lunatest.assert_nil(test_global_polluting)
		lunatest.assert_nil(_G.test_global_polluting)

		lunatest.assert_nil(some_polluting_global1)
		lunatest.assert_nil(_G.some_polluting_global1)

		lunatest.assert_nil(some_polluting_global2)
		lunatest.assert_nil(_G.some_polluting_global2)

		lunatest.assert_equal("_G.someglobal1", someglobal1)
		lunatest.assert_equal("_G.someglobal1", _G.someglobal1)
		lunatest.assert_equal("table.someglobal1", table.someglobal1)

		lunatest.assert_equal("someglobal2", someglobal2)
		lunatest.assert_equal("someglobal2", _G.someglobal2)

		lunatest.assert_equal("_G.dontchangemeglobal1", dontchangemeglobal1)
		lunatest.assert_equal("_G.dontchangemeglobal1", _G.dontchangemeglobal1)
		lunatest.assert_equal("table.dontchangemeglobal1", table.dontchangemeglobal1)

		lunatest.assert_equal("dontchangemeglobal2", dontchangemeglobal2)
		lunatest.assert_equal("dontchangemeglobal2", _G.dontchangemeglobal2)

		table.someglobal1 = "table.someglobal1_changed"
		_G.someglobal1 = "_G.someglobal1_changed"
		someglobal2 = "someglobal2_changed"

		lunatest.assert_equal("_G.someglobal1_changed", someglobal1)
		lunatest.assert_equal("_G.someglobal1_changed", _G.someglobal1)
		lunatest.assert_equal("table.someglobal1_changed", table.someglobal1)

		lunatest.assert_equal("someglobal2_changed", someglobal2)
		lunatest.assert_equal("someglobal2_changed", _G.someglobal2)

		lunatest.assert_table(_G)
		lunatest.assert_table(_G._G)
		lunatest.assert_table(_G._G._G)

		lunatest.assert_equal(_G, _G, "_G must be equal to _G")
		lunatest.assert_equal(_G, _G._G, "_G must be equal to _G._G")
		lunatest.assert_equal(_G._G, _G._G, "_G._G must be equal to _G._G")

		lunatest.assert_equal(table, _G.table, "_G.table must be equal to _G.table")
		lunatest.assert_equal(table.Copy, _G.table.Copy, "_G.table.Copy must be equal to _G.table.Copy")

		lunatest.assert_testresult_passed(result)
	end)

	lunatest.assert_true(run)
end

function suite.test_nested_testing()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(false)

	lunatest.assert_false(glunatest:IsAsynchronous())

	local async = lunatest.async(function(result)
		lunatest.assert_testresult_passed(result)
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-nested.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(20)
end
/*
function suite.test_nested_testing_overflow()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(false)

	lunatest.assert_false(glunatest:IsAsynchronous())

	local async = lunatest.async(function(result)
		lunatest.assert_testresult_passed(result)
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-nested-overflow.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(20)
end

function suite.test_nested_testing_async()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(true)

	lunatest.assert_true(glunatest:IsAsynchronous())

	local async = lunatest.async(function(result)
		lunatest.assert_testresult_passed(result)
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-nested.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(20)
end

function suite.test_nested_testing_overflow_async()
	local glunatest = CreateGLunaTestInstance()
	glunatest:EnablePrint(false)
	glunatest:SetAsynchronous(true)

	lunatest.assert_true(glunatest:IsAsynchronous())

	local async = lunatest.async(function(result)
		lunatest.assert_testresult_passed(result)
	end)

	local run = glunatest:RunTestSuite("glunatest/tests/glunatest/test-nested-overflow.lua", nil, nil, async)

	lunatest.assert_true(run)
	async:Sync(20)
end
*/
lunatest.add_tests_by_callback(suite, "add_tests_by_callback", function(i)
	if i > 100 then
		return nil
	end

	return i * 5
end, function(data, i)
	lunatest.assert_number(i)
	lunatest.assert_number(data)
	lunatest.assert_equal(i * 5, data)
end)


lunatest.add_tests_by_table(suite, "add_tests_by_table", {
	t1 = 1,
	t2 = 2,
	t3 = 3,
	t4 = 4,
}, function(key, data, i)
	lunatest.assert_number(i)
	lunatest.assert_number(data)
	lunatest.assert_string(key)

	lunatest.assert_equal(key, "t" .. data)
end)

return suite
