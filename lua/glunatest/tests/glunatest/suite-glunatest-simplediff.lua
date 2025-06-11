--[[
(C) Paul Butler 2008-2012 <http://www.paulbutler.org/>
May be used and distributed under the zlib/libpng license
<http://www.opensource.org/licenses/zlib-license.php>

Adaptation to Lua by Philippe Fremy <phil at freehackers dot org>
Lua version copyright 2015

Modified Test by Grocel
  - Adjusted to the GLunaTest environment
]]

local simplediff = GLunaTestLib.simplediff
local lunatest = package.loaded.lunatest

local suite = {}

local function is_equal( v1, v2)
	if type(v1) ~= type(v2) then return false end
	if not istable(v1) then return (v1 == v2) end
	if not istable(v2) then return (v1 == v2) end

	-- v1 and v2 are tables
	for k,v in pairs(v1) do
		if not is_equal(v1[k], v2[k]) then return false end
	end

	for k,v in pairs(v2) do
		if not v1[k] then return false end
	end
	return true
end

local function assert_equals( v1, v2, msg )
	if istable(v1) or istable(v2) then
		local result = is_equal( v1, v2 )

		lunatest.assert_true(result, msg)
		return
	end

	lunatest.assert_equal(v1, v2, msg)
end

function suite.test_table_join()
	assert_equals( simplediff.table_join( {'a', 'b', 'c' }, {1,2,3}, {'x','y','z'} ) , { 'a', 'b', 'c', 1, 2, 3, 'x', 'y', 'z' } )
	assert_equals( simplediff.table_join( {'a', 'b', 'c' }, {1,2,3} ) , { 'a', 'b', 'c', 1, 2, 3 } )
end

function suite.test_table_subtable()
	assert_equals( simplediff.table_subtable({ 1,2,3,4},0,2), {1,2} )
	assert_equals( simplediff.table_subtable({ 1,2,3,4},1,1), {} )
	assert_equals( simplediff.table_subtable({ 1,2,3,4},0,0), {} )
	assert_equals( simplediff.table_subtable({ 1,2,3,4},2), {3,4} )
end

local TEST_DATA = {
	phil= {
		{
			old= {'t', 'i', 't', 'o'},
			new= {'t', 'o', 't', 'o'},
			diff= {  {"-", {'t', 'i'}},
					 {"=", {'t', 'o'}},
					 {"+", {'t', 'o'}},
				 }
		},
	},
	insert= {
		{
			old= {1, 3, 4},
			new= {1, 2, 3, 4},
			diff= {{"=", {1}},
					 {"+", {2}},
					 {"=", {3, 4}}}
		},
		{
			old= {1, 2, 3, 8, 9, 12, 13},
			new= {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
			diff= {{"=", {1, 2, 3}},
					 {"+", {4, 5, 6, 7}},
					 {"=", {8, 9}},
					 {"+", {10, 11}},
					 {"=", {12, 13}},
					 {"+", {14, 15}}}
		},
		{
			old= {1, 2, 3, 4, 5},
			new= {1, 2, 2, 3, 4, 5},
			diff= {{"=", {1}},
					 {"+", {2}},
					 {"=", {2, 3, 4, 5}}}
		},
		{
			old= {1, 2, 3, 4, 5},
			new= {1, 2, 2, 3, 4, 4, 5},
			diff= {{"=", {1}},
					 {"+", {2}},
					 {"=", {2, 3, 4}},
					 {"+", {4}},
					 {"=", {5}}}
		},
		{
			old= {1, 2, 3, 4, 5},
			new= {1, 2, 1, 2, 3, 3, 2, 1, 4, 5},
			diff= {{"+", {1, 2}},
					 {"=", {1, 2, 3}},
					 {"+", {3, 2, 1}},
					 {"=", {4, 5}}}
		}
	},
	delete= {
		{
			old= {1, 2, 3, 4, 5},
			new= {1, 2, 5},
			diff= {{"=", {1, 2}},
					 {"-", {3, 4}},
					 {"=", {5}}}
		},
		{
			old= {1, 2, 3, 4, 5, 6, 7, 8},
			new= {3, 6, 7},
			diff= {{"-", {1, 2}},
					 {"=", {3}},
					 {"-", {4, 5}},
					 {"=", {6, 7}},
					 {"-", {8}}}
		},
		{
			old= {1, 2, 3, 4, 5, 1, 2, 3, 4, 5},
			new= {1, 2, 3, 4, 5},
			diff= {{"=", {1, 2, 3, 4, 5}},
					 {"-", {1, 2, 3, 4, 5}}}
		}
	},
	words= {
		{
			old= {"The", "quick", "brown", "fox"},
			new= {"The", "slow", "green", "turtle"},
			diff= {{"=", {"The"}},
					 {"-", {"quick", "brown", "fox"}},
					 {"+", {"slow", "green", "turtle"}}}
		},
		{
			old= {"jumps", "over", "the", "lazy", "dog"},
			new= {"walks", "around", "the", "orange", "cat"},
			diff= {{"-", {"jumps", "over"}},
					 {"+", {"walks", "around"}},
					 {"=", {"the"}},
					 {"-", {"lazy", "dog"}},
					 {"+", {"orange", "cat"}}}
		}
	}
}

for testname, testcontent in pairs(TEST_DATA) do
	suite["test_data_" .. testname] = function()
		for i, testcase in ipairs(testcontent) do
			local old=testcase.old
			local new=testcase.new
			local expected=testcase.diff
			local result = simplediff.diff(old, new)

			for i, item in ipairs(expected) do
				assert_equals(item, result[i], 'error at result #' .. i)
			end

			lunatest.assert_len(#expected, result, 'error at testcase #' .. i)
		end
	end
end

return suite
