local glfile = GLunaTestLib.file
local gljson = GLunaTestLib.json
local glconfig = GLunaTestLib.config
local lunatest = package.loaded.lunatest

local suite = {}

function suite.suite_setup()
	glfile:Delete("SELFDATA:test")
end

function suite.suite_teardown()
	glfile:Delete("SELFDATA:test")
end

function suite.test_load_simble()
	local testdata = {
		somekey = "somevalue",
		{
			10, 20, 30,
		},
		{
			"test1", "test2", "test3",
			sometable = {
				"some value with newlines \n and tabs \t to test",
				"some value with slashes / backslashes \\ and qoutes ' \" to test",
			},
		}
	}

	glfile:Write("SELFDATA:test/simble_config.txt", gljson:Encode(testdata))

	local loadeddata = glconfig:LoadConfigFile("SELFDATA:test/simble_config.txt")

	lunatest.assert_equal_ex(testdata, loadeddata)
end

function suite.test_load_include()
	glfile:Delete("SELFDATA:test")

	local testdata1 = {
		somekey = "somevalue",
		{
			10, 20, 30,
		},
		{
			"test1", "test2", "test3",
			sometable = {
				"some value with newlines \n and tabs \t to test",
				"some value with slashes / backslashes \\ and qoutes ' \" to test",
				include = "SELFDATA:test/include_config2.txt",
				overrideme = "pls no :(",
			},
			include = "SELFDATA:test/include_config2.txt",
			overrideme = "pls no :(",
		}
	}

	local testdata2 = {
		included_values = "test",
		included_table = {"a", "b", "c"},
		overrideme = "rekt",
	}

	local expected = {
		somekey = "somevalue",
		{
			10, 20, 30,
		},
		{
			"test1", "test2", "test3",
			sometable = {
				"some value with newlines \n and tabs \t to test",
				"some value with slashes / backslashes \\ and qoutes ' \" to test",
				included_values = "test",
				included_table = {"a", "b", "c"},
				overrideme = "rekt",
			},
			included_values = "test",
			included_table = {"a", "b", "c"},
			overrideme = "rekt",
		}
	}

	glfile:Write("SELFDATA:test/include_config1.txt", gljson:Encode(testdata1))
	glfile:Write("SELFDATA:test/include_config2.txt", gljson:Encode(testdata2))

	local loadeddata = glconfig:LoadConfigFile("SELFDATA:test/include_config1.txt")

	lunatest.assert_equal_ex(expected, loadeddata)
end

function suite.test_load_include_recursive()
	local testdata = {
		testdata = "X",
		R = {
			include = "SELFDATA:test/include_recursive.txt",
		},
	}


	local expected = {}
	expected.testdata = "X"
	expected.R = expected

	glfile:Write("SELFDATA:test/include_recursive.txt", gljson:Encode(testdata))

	local loadeddata = glconfig:LoadConfigFile("SELFDATA:test/include_recursive.txt")

	lunatest.assert_equal_ex(expected, loadeddata)
end

function suite.test_load_include_recursive_indirect()
	local testdata1 = {
		testdata = "X1",
		R2 = {
			include = "SELFDATA:test/include_recursive_indirect2.txt",
		},
	}

	local testdata2 = {
		testdata = "X2",
		R1 = {
			include = "SELFDATA:test/include_recursive_indirect1.txt",
		},
	}

	local expected1 = {}
	local expected2 = {}

	expected1.testdata = "X1"
	expected1.R2 = expected2

	expected2.testdata = "X2"
	expected2.R1 = expected1

	glfile:Write("SELFDATA:test/include_recursive_indirect1.txt", gljson:Encode(testdata1))
	glfile:Write("SELFDATA:test/include_recursive_indirect2.txt", gljson:Encode(testdata2))

	local loadeddata = glconfig:LoadConfigFile("SELFDATA:test/include_recursive_indirect1.txt")

	lunatest.assert_equal_ex(expected1, loadeddata)
end

return suite
