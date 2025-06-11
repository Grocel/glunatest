local gltable = GLunaTestLib.table
local lunatest = package.loaded.lunatest

local suite = {}

function suite.test_hash_reproductivity()
	local cache = {}

	local sharedA = {
		"shared table",
		"test",
	}

	local sharedB = {
		"shared table2",
		"test",
		[sharedA] = "nested",
	}

	for i=1, 100 do
		local privateA = {
			"private",
			i,
		}

		local privateB = {
			"private",
			i,
		}

		local tableA = {
			"test1",
			test1 = {
				"subtest1",
				"some\r\ndata",
				ggg = "aaa1",
				[NULL] = NULL,
				[false] = true,
				[true] = false,
			},
			[sharedA] = "A",
			[sharedB] = sharedB,
			[privateA] = privateA,
		}

		tableA.nested = tableA
		tableA.nested2 = tableA
		tableA[tableA] = tableA

		local tableB = {
			"test1",
			test1 = {
				"subtest1",
				"some\r\ndata",
				ggg = "aaa1",
				[NULL] = NULL,
				[false] = true,
				[true] = false,
			},
			[sharedA] = "A",
			[sharedB] = sharedB,
			[privateB] = privateB,
		}

		tableB.nested = tableB
		tableB.nested2 = tableB
		tableB[tableB] = tableB

		local hashA = gltable:Hash(tableA, cache)
		local hashB = gltable:Hash(tableB, cache)

		lunatest.assert_equal(hashA, hashB)
	end
end

local unique_hashes = {}

lunatest.add_tests_by_table(suite, "hash", {
	{"", "JM53A505BEFA31C91EC92B40ED7BF36EB6175D4E5B68C05D9A46532008D6A815C3"},
	{"some test string", "JM74E25F31EFCB42159B7A8AE78933D73F7FBE68FD02C72F7FFD0B46A0F05D4F13"},
	{"85CCC97CF2905418C850C0E5CA49A663", "JM57551C3993C7A15D38FB60BEB13C937433298F40FE4D6615364971539665F3CA"},
	{"C850C0E5CA49A66385CCC97CF2905418", "JM0382071481F08EAF3EE082743869ABE70B104FB5DDB6467185ACE36769C5F088"},

	{Vector(), "JME5D9C5FE5569BAA9EDFC802F0770A326380BB9D3A1883F6B3E876EB930DB5686"},
	{Angle(), "JMF57374082330ED93E931C0F69DD01949443C46C695DA698A71602BC5FD62BA0D"},
	{Vector(1, 2, 3), "JM2945DB82EE0F8F5A837D1579476EB0A37EF38425E7644C314965452CEC138F1C"},
	{Angle(1, 2, 3), "JM6F1964F12AF4D37F63E2A56BBDF7021043707315ABF4B7DC5BC0D5337B8BB607"},

	{{}, "KR69A13277A4CF1299975D281F22ADCB7B9692B83C0A5629E78D4CD8B00C522C58"},
	{{""}, "JMCEE9C9053A7019DC7926F2FE13ED95066FE9DC90D95B13AF4603D0EB3911256D"},
	{{"some test string"}, "JM9184F779EB7D3553FD97E903D0100B97ACAB994A0AAEC2E4C8E11D84407CE1A8"},
	{{"85CCC97CF2905418C850C0E5CA49A663"}, "JM535A05C0F340A09FFC8FB89F0C2CA6F379E918B956821AB748D9286A25C27A02"},
	{{"C850C0E5CA49A66385CCC97CF2905418"}, "JM3C2632911F36DEE389278B224DFEC8B9FE098B8531C8F68B48DD5D5F28B5F476"},

	{{Vector()}, "JM30CA5635D7152DC8BF8483376859AD14E772CB892034D151AF8CF556D2F9C341"},
	{{Angle()}, "JMF3CF04FDE250E71C8C82DAF50086511110104BAE90E137023E3DEFE9EEEF9063"},
	{{Vector(1, 2, 3)}, "JMCC59C20F386ABB9F28CABC24D4241D803534D22251A4AB9F6F505C030F0DE816"},
	{{Angle(1, 2, 3)}, "JM2CE9F565AE9FF9199B6ABD96383AD226A85308A2971C8CB2E1A8CEEC4E201DEF"},

	{{{}}, "JM3123624CE814DF6E80F968E9EE65122F0B6189D89C0970B12E22135FBCF782F2"},
	{{{""}}, "JM14CF9EF1A7AFB52EB409791E651D3738D875E1023E8F019E12A45195386B3904"},
	{{{"some test string"}}, "JM275A06154A6FBEB710F03E7CA63CB3B36C8DC86D362029E3E42606E149555330"},
	{{{"85CCC97CF2905418C850C0E5CA49A663"}}, "JMFA2568D9D6A0D616DF8933C693AB25C14675029D399E11F7813CE0CDE0242F20"},
	{{{"C850C0E5CA49A66385CCC97CF2905418"}}, "JM4CB150BE140BA5489A6134E6A968F5F4B13E90689B4A3C36F032CDBAF41FABA6"},

	{{{Vector()}}, "JM126F056AA65BF3F8BB662A5E23106398CDA0FB7503F1A708724C187D829228FD"},
	{{{Angle()}}, "JM49CC2F5DB6C4937D5EB94C18AC0078ECBFA0FEC3A7BFA660DB5410DD021F730E"},
	{{{Vector(1, 2, 3)}}, "JM2B5E80D1CD6810C2B7F862125B4CADF03EB05C8B510005A80B9884F8CEB49607"},
	{{{Angle(1, 2, 3)}}, "JM325D09F199AB86AE00E1550CF1D6A4E6E6D87BEE3929D3136B20F69FB3CCC61E"},

}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local hash = gltable:Hash(input)

	if unique_hashes[hash] then
		lunatest.fail("Hash collision detected, hash: " .. hash, true)
	end

	unique_hashes[hash] = true

	lunatest.assert_equal(expected, hash)
end)

function suite.test_tostring()
	for i=1, 1 do
		local keytable1A = {
			test1 = {
				"subtest1",
				ggg = "aaa1",
			},
		}

		local keytable1B = {
			test2 = {
				"subtest2",
				ggg = "aaa2",
			},
		}

		local testtable = {
			"test1",
			key = "value",
			lib = sound,
			[sound] = "sound",
			[sound.Add] = sound.Add,
			[true] = false,
			[false] = true,
			table = {
				key2 = "val2",
				[NULL] = NULL,
				nestedkey = {},
			},
			nested2 = {
				a = {
					"some\r\ndata",
					1234,
				},
			},
			[keytable1A] = {
				test2 = {
					"subtest2",
					ggg = "aaa2",
				},
			},
		}

		testtable.nested = testtable
		testtable.nested2.b = testtable.nested2.a
		testtable.table.nested = testtable
		testtable.table.nestedkey[keytable1A] = {"nested"}
		testtable[testtable] = {"nested"}
		testtable[keytable1B] = keytable1B

		local keytable2A = {
			test1 = {
				"subtest1",
				ggg = "aaa1",
			},
		}

		local keytable2B = {
			test2 = {
				"subtest2",
				ggg = "aaa2",
			},
		}

		local testtable2 = {
			"test1",
			key = "value",
			lib = sound,
			[sound] = "sound",
			[sound.Add] = sound.Add,
			[true] = false,
			[false] = true,
			table = {
				key2 = "val2",
				[NULL] = NULL,
				nestedkey = {},
			},
			nested2 = {
				a = {
					"some\r\ndata",
					1234,
				},
			},
			[keytable2A] = {
				test2 = {
					"subtest2",
					ggg = "aaa2",
				},
			},
		}

		testtable2.nested = testtable2
		testtable2.nested2.b = testtable2.nested2.a
		testtable2.table.nested = testtable2
		testtable2.table.nestedkey[keytable2A] = {"nested"}
		testtable2[testtable2] = {"nested"}
		testtable2[keytable2B] = keytable2B

		local A = gltable:ToString(testtable)
		local B = gltable:ToString(testtable2)

		lunatest.assert_equal(A, B)
	end
end

function suite.test_sortbyvalues_mixedtypes()
	local T = {}
	local F = (function() end)
	local CF = unpack

	local tosort = {
		{
			V = true,
		},
		{
			V = false,
		},
		{},
		{
			V = 0,
		},
		{
			V = 1,
		},
		{
			V = 2,
		},
		{
			V = "1",
		},
		{
			V = "2",
		},
		{
			V = "string1",
		},
		{
			V = "string2",
		},
		{
			V = T,
		},
		{
			V = F,
		},
		{
			V = CF,
		},
	}

	local sorted = {
		{},
		{
			["V"] = false
		},
		{
			["V"] = true
		},
		{
			["V"] = F
		},
		{
			["V"] = CF
		},
		{
			["V"] = 0
		},
		{
			["V"] = 1
		},
		{
			["V"] = 2
		},
		{
			["V"] = "1"
		},
		{
			["V"] = "2"
		},
		{
			["V"] = "string1"
		},
		{
			["V"] = "string2"
		},
		{
			["V"] = T
		}
	}


	tosort = gltable:sortByValues(tosort, "V")

	lunatest.assert_equal_ex(sorted, tosort)
end

function suite.test_sortbyvalues_multisort()
	local tosort = {
		{
			A1 = "1",
			A2 = "1",
			A3 = "Please",
		},
		{
			A1 = "1",
			A2 = "2",
			A3 = "Sort",
		},
		{
			A1 = "1",
			A2 = "2",
			A3 = "Me",
		},
		{
			A1 = "3",
			A2 = "2",
			A3 = "Now",
		},
		{
			A1 = "3",
			A2 = "1",
			A3 = "For",
		},
		{
			A1 = "3",
			A2 = "0",
			A3 = "The",
		},
		{
			A1 = "0",
			A2 = "3",
			A3 = "Test",
		},
		{
			A1 = "2",
			A2 = "3",
		},
		{
			A1 = "1",
			A2 = "3",
		},
	}

	local sorted = {
		{
			["A1"] = "3",
			["A2"] = "0",
			["A3"] = "The"
		},
		{
			["A1"] = "1",
			["A2"] = "1",
			["A3"] = "Please"
		},
		{
			["A1"] = "3",
			["A2"] = "1",
			["A3"] = "For"
		},
		{
			["A1"] = "1",
			["A2"] = "2",
			["A3"] = "Me"
		},
		{
			["A1"] = "1",
			["A2"] = "2",
			["A3"] = "Sort"
		},
		{
			["A1"] = "3",
			["A2"] = "2",
			["A3"] = "Now"
		},
		{
			["A1"] = "0",
			["A2"] = "3",
			["A3"] = "Test"
		},
		{
			["A1"] = "1",
			["A2"] = "3"
		},
		{
			["A1"] = "2",
			["A2"] = "3"
		}
	}

	tosort = gltable:sortByValues(tosort, "A2", "A1", "A3")

	lunatest.assert_equal_ex(sorted, tosort)
end

function suite.test_compare()
	local R1 = {"R"}

	R1.R = R1
	R1[R1] = R1

	local R2 = {"R"}

	R2.R = R2
	R2[R2] = R2

	local A = {
		"test1",
		"test2",
		"test3",
		{
			["a"] = "test123",
			["b"] = "test123",
			["c"] = "test123",
		},
		[{
			"testKey",
		}] = "testKeyValue",
		R1,
	}

	local B = {
		"test1",
		"test2",
		"test3",
		{
			["a"] = "test123",
			["b"] = "test123",
			["c"] = "test123",
		},
		[{
			"testKey",
		}] = "testKeyValue",
		R2,
	}

	local issame = gltable:Compare(A, B)
	lunatest.assert_true(issame)
end

function suite.test_merge()
	local R1 = {"R"}
	R1.R = R1

	local R2 = {"R"}
	R2.R = R2

	local A = {
		"A",
		"B",
		"C",
		keyA = "value",
		keyC = "value",
		subTableA = {1,2,3},
		subTableB = {
			one = 1,
			two = 2,
			three = 3,
			four = 4,
		},
		subTableMixed = {
			someKeyA = "A1",
			someKeyB = {"A2"},
			someKeyC = "A3",
			someKeyD = {"A4", "C4"},
			someKeyE = {A = "A5"},
			someKeyF = "A6",
		},
		R1 = R1,
	}

	local B = {
		"D",
		"E",
		"F",
		keyB = "value2",
		keyC = "value_override",
		subTableA = {4,5,6},
		subTableB = {
			one = 4,
			two = 5,
			three = 6,
		},
		subTableMixed = {
			someKeyA = "B1",
			someKeyB = "B2",
			someKeyC = {"B3"},
			someKeyD = {"B4", "D4"},
			someKeyE = "B5",
			someKeyF = {B = "B6"},
		},
		R2 = R2,
	}

	local merged = gltable:Merge(A, B, false)
	local expected = {
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		keyA = "value",
		keyB = "value2",
		keyC = "value_override",
		subTableA = {4,5,6},
		subTableB = {
			one = 4,
			two = 5,
			three = 6,
		},
		subTableMixed = {
			someKeyA = "B1",
			someKeyB = "B2",
			someKeyC = {"B3"},
			someKeyD = {"B4", "D4"},
			someKeyE = "B5",
			someKeyF = {B = "B6"},
		},
		R1 = R1,
		R2 = R2,
	}

	lunatest.assert_equal(A, merged)
	lunatest.assert_equal_ex(expected, merged)
end

function suite.test_merge_recursive()
	local R1 = {"R"}
	R1.R = R1

	local R2 = {"R"}
	R2.R = R2

	local A = {
		"A",
		"B",
		"C",
		keyA = "value",
		keyC = "value",
		subTableA = {1,2,3},
		subTableB = {
			one = 1,
			two = 2,
			three = 3,
			four = 4,
		},
		subTableMixed = {
			someKeyA = "A1",
			someKeyB = {"A2"},
			someKeyC = "A3",
			someKeyD = {"A4", "C4"},
			someKeyE = {A = "A5"},
			someKeyF = "A6",
		},
		R1 = R1,
	}

	local B = {
		"D",
		"E",
		"F",
		keyB = "value2",
		keyC = "value_override",
		subTableA = {4,5,6},
		subTableB = {
			one = 4,
			two = 5,
			three = 6,
		},
		subTableMixed = {
			someKeyA = "B1",
			someKeyB = "B2",
			someKeyC = {"B3"},
			someKeyD = {"B4", "D4"},
			someKeyE = "B5",
			someKeyF = {B = "B6"},
		},
		R2 = R2,
	}

	local merged = gltable:Merge(A, B, true)
	local expected = {
		"A",
		"B",
		"C",
		"D",
		"E",
		"F",
		keyA = "value",
		keyB = "value2",
		keyC = "value_override",
		subTableA = {1,2,3,4,5,6},
		subTableB = {
			one = 4,
			two = 5,
			three = 6,
			four = 4,
		},
		subTableMixed = {
			someKeyA = "B1",
			someKeyB = {"A2", "B2"},
			someKeyC = {"A3", "B3"},
			someKeyD = {"A4", "C4", "B4", "D4"},
			someKeyE = {A = "A5", "B5"},
			someKeyF = {"A6", B = "B6"},
		},
		R1 = R1,
		R2 = R2,
	}

	lunatest.assert_equal(A, merged)
	lunatest.assert_equal_ex(expected, merged)
end

return suite
