local gljson = GLunaTestLib.json
local glstring = GLunaTestLib.string
local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_encode()
	local T = {
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

	local expected = [[{
	"1": [
		10,
		20,
		30
	],
	"2": {
		"1": "test1",
		"2": "test2",
		"3": "test3",
		"sometable": [
			"some value with newlines \n and tabs \t to test",
			"some value with slashes / backslashes \\ and qoutes ' \" to test"
		]
	},
	"somekey": "somevalue"
}]]

	expected = glstring:NormalizeNewlines(expected, "\n")

	local result = gljson:Encode(T, true)

	lunatest.assert_equal_ex(expected, result)
end

function suite.test_decode()
	local S = [[

	{

		// this test decoding non standard JSON

		"1": [
			10.0,
			20.0,
			30.0, /* leading commas */
		],

		"2": {
			"1": "test1", // Comments
			"2": "test2",
			"3": "test3",

			"sometable": [
				"some value with newlines \n and tabs \t to test",
				"some value with slashes / backslashes \\ and qoutes ' \" to test",
				/*
					A
					multiline
					comment
				*/
			],
		},


		"somekey": "somevalue",

	}

]]

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
			},
		}
	}

	local result = gljson:Decode(S)

	lunatest.assert_equal_ex(expected, result)
end


return suite
