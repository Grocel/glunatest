local glfile = GLunaTestLib.file
local lunatest = package.loaded.lunatest

local suite = {}

lunatest.add_tests_by_table(suite, "sanitizefilename", {
	{"", ""},
	{"THISname", "thisname"},
	{"   a NAME with spaces  ", "a_name_with_spaces"},
	{"a NAME with\nnewline", "a_name_with_newline"},
	{"a NAME    with spaces and\ttabs	tabs", "a_name_with_spaces_and_tabs_tabs"},
	{"a dash-NAME with illegal*+~#'chars", "a_dash-name_with_illegal-----chars"},

	{".\\my\\//file\\name\\\\here.txt", "my/file/name/here.txt"},
	{"./data/../my\\//file\\name\\\\here_with dots....txt", "data/my/file/name/here_with_dots....txt"},
	{"data\\..\\..//..\\ab/./cd_#+'\"-_.test", "data/ab/cd_-----_.test"},
}, function(key, data, index)
	local input = data[1]
	local expected = data[2]

	local output = glfile:SanitizeFilename(input)
	lunatest.assert_equal(expected, output)
end)

lunatest.add_tests_by_table(suite, "resolvepath", {
	{"this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA"},
	{"DATA:this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA"},
	{"SELF:this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "SELF", "glunatest/this/is/a/path/toafile.txt", "DATA"},
	{"SELFDATA:this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "SELFDATA", "glunatest/this/is/a/path/toafile.txt", "DATA"},
	{"CONFIG:this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "CONFIG", "glunatest/config/this/is/a/path/toafile.txt", "DATA"},
	{"CACHE:this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},
	{"LOG:this/is/a/path/toafile.txt", "this/is/a/path/toafile.txt", "LOG", "glunatest/log/this/is/a/path/toafile.txt", "DATA"},

	{"LUA:this/is/a/path/toafile.lua", "this/is/a/path/toafile.lua", "LUA", "this/is/a/path/toafile.lua", "LUA"},
	{"LSV:this/is/a/path/toafile.lua", "this/is/a/path/toafile.lua", "LSV", "this/is/a/path/toafile.lua", "lsv"},
	{"LCL:this/is/a/path/toafile.lua", "this/is/a/path/toafile.lua", "LCL", "this/is/a/path/toafile.lua", "lcl"},
	{"SELFLUA:this/is/a/path/toafile.lua", "this/is/a/path/toafile.lua", "SELFLUA", "glunatest/this/is/a/path/toafile.lua", "LUA"},

	{"GAME:this/is/afile.mdl", "this/is/afile.mdl", "GAME", "this/is/afile.mdl", "GAME"},
	{"MOD:this/is/afile.mdl", "this/is/afile.mdl", "MOD", "this/is/afile.mdl", "MOD"},
	{"DOWNLOAD:this/is/afile.mdl", "this/is/afile.mdl", "DOWNLOAD", "this/is/afile.mdl", "DOWNLOAD"},
	{"THIRDPARTY:this/is/afile.mdl", "this/is/afile.mdl", "THIRDPARTY", "this/is/afile.mdl", "THIRDPARTY"},
	{"WORKSHOP:this/is/afile.mdl", "this/is/afile.mdl", "WORKSHOP", "this/is/afile.mdl", "WORKSHOP"},

	{"ADDON[glunatest]:this/is/anaddonfile.vtx", "this/is/anaddonfile.vtx", "ADDON[glunatest]", "addons/glunatest/this/is/anaddonfile.vtx", "GAME"},
	{"ADDON['glunatest']:this/is/anaddonfile.vtx", "this/is/anaddonfile.vtx", "ADDON['glunatest']", "addons/glunatest/this/is/anaddonfile.vtx", "GAME"},
	{'ADDON["glunatest"]:this/is/anaddonfile.vtx', "this/is/anaddonfile.vtx", 'ADDON["glunatest"]', "addons/glunatest/this/is/anaddonfile.vtx", "GAME"},
}, function(key, data, index)
	local path = data[1]

	local expected_vpath = data[2]
	local expected_vmount = data[3]
	local expected_rpath = data[4]
	local expected_rmount = data[5]

	local pathobject = glfile:ResolvePath(path)

	lunatest.assert_equal(expected_vpath, pathobject:GetVirtualPath())
	lunatest.assert_equal(expected_vmount, pathobject:GetVirtualMount())
	lunatest.assert_equal(expected_rpath, pathobject:GetRealPath())
	lunatest.assert_equal(expected_rmount, pathobject:GetRealMount())
end)

lunatest.add_tests_by_table(suite, "resolvepath_default_mount", {
	{"this/is/a/path/toafile.txt", nil, "this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA"},
	{"this/is/a/path/toafile.txt", "", "this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA"},
	{"this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA"},
	{"this/is/a/path/toafile.lua", "LUA", "this/is/a/path/toafile.lua", "LUA", "this/is/a/path/toafile.lua", "LUA"},
	{"this/is/a/path/toafile.txt", "CONFIG", "this/is/a/path/toafile.txt", "CONFIG", "glunatest/config/this/is/a/path/toafile.txt", "DATA"},

	{"GAME:this/is/a/path/toafile.mdl", nil, "this/is/a/path/toafile.mdl", "GAME", "this/is/a/path/toafile.mdl", "GAME"},
	{"GAME:this/is/a/path/toafile.mdl", "", "this/is/a/path/toafile.mdl", "GAME", "this/is/a/path/toafile.mdl", "GAME"},
	{"GAME:this/is/a/path/toafile.mdl", "DATA", "this/is/a/path/toafile.mdl", "GAME", "this/is/a/path/toafile.mdl", "GAME"},
	{"GAME:this/is/a/path/toafile.mdl", "LUA", "this/is/a/path/toafile.mdl", "GAME", "this/is/a/path/toafile.mdl", "GAME"},
	{"GAME:this/is/a/path/toafile.mdl", "CONFIG", "this/is/a/path/toafile.mdl", "GAME", "this/is/a/path/toafile.mdl", "GAME"},

	{"CACHE:this/is/a/path/toafile.txt", nil, "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},
	{"CACHE:this/is/a/path/toafile.txt", "", "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},
	{"CACHE:this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},
	{"CACHE:this/is/a/path/toafile.txt", "LUA", "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},
	{"CACHE:this/is/a/path/toafile.txt", "CONFIG", "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},

	{glfile:ResolvePath("this/is/a/path/toafile.txt", "CACHE"), "DOWNLOAD", "this/is/a/path/toafile.txt", "CACHE", "glunatest/cache/this/is/a/path/toafile.txt", "DATA"},
	{glfile:ResolvePath("this/is/a/path/toafile.txt"),          "DOWNLOAD", "this/is/a/path/toafile.txt", "DATA", "this/is/a/path/toafile.txt", "DATA"},
	{glfile:ResolvePath("GAME:this/is/a/path/toafile.mdl"),     "DOWNLOAD", "this/is/a/path/toafile.mdl", "GAME", "this/is/a/path/toafile.mdl", "GAME"},
}, function(key, data, index)
	local path = data[1]
	local defaultmount = data[2]

	local expected_vpath = data[3]
	local expected_vmount = data[4]
	local expected_rpath = data[5]
	local expected_rmount = data[6]

	local pathobject = glfile:ResolvePath(path, defaultmount)

	lunatest.assert_equal(expected_vpath, pathobject:GetVirtualPath())
	lunatest.assert_equal(expected_vmount, pathobject:GetVirtualMount())
	lunatest.assert_equal(expected_rpath, pathobject:GetRealPath())
	lunatest.assert_equal(expected_rmount, pathobject:GetRealMount())
end)

function suite.test_resolvepath_reuse()
	local path = "SELFDATA:this/is/a/path/toafile.txt"

	local expected_vpath = "this/is/a/path/toafile.txt"
	local expected_vmount = "SELFDATA"
	local expected_rpath = "glunatest/this/is/a/path/toafile.txt"
	local expected_rmount = "DATA"

	local pathobject = path

	for i = 1, 10 do
		pathobject = glfile:ResolvePath(pathobject)

		lunatest.assert_equal(expected_vpath, pathobject:GetVirtualPath())
		lunatest.assert_equal(expected_vmount, pathobject:GetVirtualMount())
		lunatest.assert_equal(expected_rpath, pathobject:GetRealPath())
		lunatest.assert_equal(expected_rmount, pathobject:GetRealMount())
	end

end

return suite
