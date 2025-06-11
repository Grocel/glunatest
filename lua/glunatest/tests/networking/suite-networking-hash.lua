local glnet = GLunaTestLib.net
local lunatest = package.loaded.lunatest

local suite = {}

lunatest.add_tests_by_table(suite, "hash", {
	{"", "2A339304D7FF40547639BC3DE7EBC15A"},
	{"some test string", "00543FDA9BF41049D8DF8D700A36C1A6"},

	{"C850C0E5CA49A663", "8C0E9FBBFAE83AAAAC4D3E6763EBCE20"},
	{"85CCC97CF2905418", "64C4B4FEBDB558FEAB51D5053EFEC6AD"},
	{"85CCC97CF2905418C850C0E5CA49A663", "B0BA580B83EE38F9507E443DEE8AE8FE"},
	{"C850C0E5CA49A66385CCC97CF2905418", "A40439A8C146AE11282B05B2C8F00510"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local hash = glnet:Hash(input)

	lunatest.assert_equal(expected, hash)
end)

lunatest.add_tests_by_table(suite, "hash_compare", {
	{"some test string", "some test string", true},
	{"", "some test string", false},
	{"some test string", "", false},

	{"cccccccccc", "some test string", false},
	{"some test string", "cccccccccc", false},

	{"", "", true},
	{"cccccccccc", "cccccccccc", true},
	{"a", "a", true},
	{"a", "b", false},
	{"b", "a", false},

	{"85CCC97CF2905418C850C0E5CA49A663", "85CCC97CF2905418C850C0E5CA49A663", true},
	{"C850C0E5CA49A66385CCC97CF2905418", "85CCC97CF2905418C850C0E5CA49A663", false},
	{"85CCC97CF2905418C850C0E5CA49A663", "C850C0E5CA49A66385CCC97CF2905418", false},

}, function(key, data, index)
	local input1 = data[1]
	local input2 = data[2]
	local expected = data[3]

	local hash1 = glnet:Hash(input1)
	local hash2 = glnet:Hash(input2)

	local same = glnet:HashCompare(hash1, hash2)

	lunatest.assert_equal(expected, same)
end)

lunatest.add_tests_by_table(suite, "add_validate_and_remove", {
	"",
	"some test string",

	"85CCC97CF2905418C850C0E5CA49A663",
	"C850C0E5CA49A66385CCC97CF2905418",
	"a",
	"b",
	"c",

	"cccccccccc",
}, function(key, data, index)
	local dataWithAddedHash = glnet:CalculateAndAddHash(data)
	lunatest.assert_not_equal(data, dataWithAddedHash)

	local validatedData = glnet:ValidateAndRemoveHash(dataWithAddedHash)
	lunatest.assert_not_nil(validatedData)
	lunatest.assert_equal_bytes(data, validatedData)
end)


return suite
