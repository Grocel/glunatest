local lunatest = require "lunatest"

function test_glunatest_testlevel()
	lunatest.assert_equal(2, lunatest.TESTLEVEL)
end

function test_global_polluting()
	_G.some_polluting_global1 = "_G.some_polluting_global1"
	some_polluting_global2 = "some_polluting_global2"

	lunatest.assert_nil(test_glunatest_global_pollute)
	lunatest.assert_nil(_G.test_glunatest_global_pollute)

	lunatest.assert_nil(test_glunatest_teardown_fail)
	lunatest.assert_nil(_G.test_glunatest_teardown_fail)

	lunatest.assert_equal("_G.someglobal1", someglobal1)
	lunatest.assert_equal("_G.someglobal1", _G.someglobal1)

	lunatest.assert_equal("someglobal2", someglobal2)
	lunatest.assert_equal("someglobal2", _G.someglobal2)

	lunatest.assert_equal("_G.dontchangemeglobal1", dontchangemeglobal1)
	lunatest.assert_equal("_G.dontchangemeglobal1", _G.dontchangemeglobal1)

	lunatest.assert_equal("dontchangemeglobal2", dontchangemeglobal2)
	lunatest.assert_equal("dontchangemeglobal2", _G.dontchangemeglobal2)

	lunatest.assert_equal("_G.some_polluting_global1", some_polluting_global1)
	lunatest.assert_equal("_G.some_polluting_global1", _G.some_polluting_global1)

	lunatest.assert_equal("some_polluting_global2", some_polluting_global2)
	lunatest.assert_equal("some_polluting_global2", _G.some_polluting_global2)

	_G.dontchangemeglobal1 = "_G.imchanged_global1"
	dontchangemeglobal2 = "imchanged_global2"

	lunatest.assert_equal("_G.imchanged_global1", dontchangemeglobal1)
	lunatest.assert_equal("_G.imchanged_global1", _G.dontchangemeglobal1)

	lunatest.assert_equal("imchanged_global2", dontchangemeglobal2)
	lunatest.assert_equal("imchanged_global2", _G.dontchangemeglobal2)

	lunatest.assert_table(_G)
	lunatest.assert_table(_G._G)
	lunatest.assert_table(_G._G._G)

	lunatest.assert_equal(_G, _G, "_G must be equal to _G")
	lunatest.assert_equal(_G, _G._G, "_G must be equal to _G._G")
	lunatest.assert_equal(_G._G, _G._G, "_G._G must be equal to _G._G")
end

function test_global_polluting_subtable()
	table.some_polluting_global1 = "table.some_polluting_global1"

	lunatest.assert_function(table.Copy)

	lunatest.assert_equal("table.someglobal1", table.someglobal1)
	lunatest.assert_equal("table.dontchangemeglobal1", table.dontchangemeglobal1)
	lunatest.assert_equal("table.some_polluting_global1", table.some_polluting_global1)

	table.dontchangemeglobal1 = "table.imchanged_global1"

	lunatest.assert_equal("table.imchanged_global1", table.dontchangemeglobal1)

	lunatest.assert_equal(table, _G.table, "_G.table must be equal to _G.table")
	lunatest.assert_equal(table.Copy, _G.table.Copy, "_G.table.Copy must be equal to _G.table.Copy")

end


lunatest.run()
