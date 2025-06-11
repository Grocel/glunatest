if not GLUNATEST then
   return
end
local LIB = GLunaTestLib

local libString = LIB.string
local libTable = LIB.table
local libPrint = LIB.print
local libFile = LIB.file
local libCoroutine = LIB.coroutine
local libMock = LIB.mock

local glunatest = GLUNATEST

local cache = {}

local upvaluebacklist = {
	print = true,
	error = true,
	require = true,
	io = true,
	os = true,
}

local IsValid = IsValid
local type = type
local pcall = pcall

local glunatestGetUpvalueSources = {
	glunatest.fail,
	glunatest.skip,
	glunatest.warning,
	glunatest.assert_true,
	glunatest.assert_false,
	glunatest.assert_nil,
	glunatest.assert_error,
	glunatest.suite,
	glunatest.run,
	glunatest.is_test_key,
}

function glunatest.getUpValues( func )
	func = func or glunatestGetUpvalueSources

	local name = tostring(func or "")
	if cache[name] then
		return cache[name]
	end

	if istable(func) then
		local upvalues = {}
		cache[name] = upvalues

		for k, v in pairs(func) do
			if not isfunction(v) and not istable(v) then
				continue
			end

			local thisupvalues = glunatest.getUpValues(v)

			for thisupvaluekey, thisupvalue in pairs(thisupvalues) do
				upvalues[thisupvaluekey] = thisupvalue
			end
		end

		cache[name] = upvalues
		return upvalues
	end

	if not isfunction(func) then
		error("Bad function call, argument #1 must be a function or a table!", 1)
	end

	local info = debug.getinfo(func, "uS")
	local upvalues = {}
	cache[name] = upvalues

	if info ~= nil and info.what == "Lua" then
		local nups = info.nups

		for i = 1, nups do
			local key, value = debug.getupvalue(func, i)

			if not key then continue end
			if value == nil then continue end

			if value == cache then continue end

			if value == upvaluebacklist then continue end
			if upvaluebacklist[key] then continue end

			if _G == value then continue end
			if _G[key] == value then continue end

			if LIB == value then continue end
			if table.HasValue(LIB, value) then continue end

			upvalues[key] = value
		end
	end

	cache[name] = upvalues
	return upvalues
end

function glunatest.getUpValue(func, index)
	local upvalues = glunatest.getUpValues(func)
	return upvalues[index]
end


function glunatest.getUpValueFromSelf(index)
	local upvalue = glunatest.getUpValue(nil, index)
	return upvalue
end

function glunatest.getLocalFunction(func, name)
	local upvalue = glunatest.getUpValue(func, name)
	if not isfunction(upvalue) then return nil end

	return upvalue
end

function glunatest.getLocalFunctionFromSelf(name)
	local upvalue = glunatest.getUpValueFromSelf(name)
	if not isfunction(upvalue) then return nil end

	return upvalue
end

glunatest._wraptest = glunatest.getLocalFunctionFromSelf("wraptest")
glunatest._Pass = glunatest.getLocalFunctionFromSelf("Pass")
glunatest._Fail = glunatest.getLocalFunctionFromSelf("Fail")
glunatest._Skip = glunatest.getLocalFunctionFromSelf("Skip")
glunatest._Warning = glunatest.getLocalFunctionFromSelf("Warning")
glunatest._Error = glunatest.getLocalFunctionFromSelf("Error")

local _fmt = string.format
local _strlw = string.lower

local _wraptest = glunatest._wraptest
local _pass = glunatest._Pass
local _fail = glunatest._Fail
local _skip = glunatest._Skip
local _warning = glunatest._Warning
local _error = glunatest._Error

function glunatest.add_assertion_function(name, checkcallback, faildatacallback, argcount)
	name = libString:SanitizeFunctionName(name)

	if name == "" then
		return false
	end

	if not isfunction(checkcallback) then
		return false
	end

	argcount = tonumber(argcount or 0) or 0

	if argcount < 0 then
		argcount = 0
	end

	glunatest["assert_" .. name] = function(val, ...)
		local faildata = nil

		local args = {...}
		local msg = args[argcount + 1]
		args[argcount + 1] = nil

		if isfunction(faildatacallback) then
			faildata = faildatacallback(val, unpack(args))
		else
			faildata = faildatacallback
		end

		if not istable(faildata) then
			faildata = {faildata}
		end

		_wraptest(
			tobool(checkcallback(val, unpack(args))),
			msg,
			faildata
		)
	end

	return true
end

function glunatest.remove_assertion_function(name)
	name = libString:SanitizeFunctionName(name)

	if name == "" then
		return false
	end

	glunatest["assert_" .. name] = nil
	return true
end

function glunatest.add_type_assertion_function(typename, checkfunc, notcheckfunc)
	if not isfunction(checkfunc) then
		checkfunc = nil
	end

	if not isfunction(notcheckfunc) then
		notcheckfunc = nil
	end

	if not checkfunc and not notcheckfunc then
		return false
	end

	local typefuncname = libString:SanitizeFunctionName(typename)
	local nottypefuncname = "not_" .. typefuncname

	if typename == "" then
		return false
	end

	if typefuncname == "" then
		return false
	end

	checkfunc = checkfunc or (function(val)
		return not notcheckfunc(val)
	end)

	notcheckfunc = notcheckfunc or (function(val)
		return not checkfunc(val)
	end)

	local added = false

	added = glunatest.add_assertion_function(typefuncname, checkfunc, function(val)
		return {
			reason = _fmt("Expected type %s but got %s", typename, type(val))
		}
	end)

	if not added then
		glunatest.remove_assertion_function(typefuncname)
		return false
	end

	added = glunatest.add_assertion_function(nottypefuncname, notcheckfunc, function(val)
		return {
			reason = _fmt("Expected type other than %s but got %s", typename, type(val))
		}
	end)

	if not added then
		glunatest.remove_assertion_function(typefuncname)
		glunatest.remove_assertion_function(nottypefuncname)
		return false
	end

	return true
end

glunatest.add_assertion_function("type", function(val, typename)
	local thistype = type(val)
	return thistype == typename
end, function(val, typename)
	local thistype = type(val)
	return {
		reason = _fmt("Expected type %s but got %s", typename, thistype)
	}
end, 1)

glunatest.add_assertion_function("not_type", function(val, typename)
	local thistype = type(val)
	return thistype ~= typename
end, function(val, typename)
	local thistype = type(val)
	return {
		reason = _fmt("Expected type other than %s but got %s", typename, thistype)
	}
end, 1)

glunatest.add_assertion_function("typeid", function(val, typeid)
	local thistypeid = TypeID(val)
	return thistype == typename
end, function(val, typeid)
	local thistypeid = TypeID(val)
	return {
		reason = _fmt("Expected typeid %s but got %s", typeid, thistypeid)
	}
end, 1)

glunatest.add_assertion_function("not_typeid", function(val, typeid)
	local thistype = TypeID(val)
	return thistype ~= typename
end, function(val, typeid)
	local thistype = TypeID(val)
	return {
		reason = _fmt("Expected typeid other than %s but got %s", typeid, thistypeid)
	}
end, 1)

local asserttypelist = {
	["userdata"] = {
		checkfunc = (function(val)
			return _strlw(type(val)) == "userdata"
		end),

		notcheckfunc = (function(val)
			return _strlw(type(val)) ~= "userdata"
		end),
	},
}

for typename, v in pairs(asserttypelist) do
	local checkfunc = v.checkfunc
	local notcheckfunc = v.notcheckfunc

	glunatest.add_type_assertion_function(typename, checkfunc, notcheckfunc)
end


function glunatest.assert_testresult_passed(testResult, strict, msg)
	if strict == nil then
		strict = true
	end

	local pass = false
	local strictadverp = ""

	if strict then
		pass = testResult:hasPassedStrict()
		strictadverp = "STRICTLY "
	else
		pass = testResult:hasPassed()
	end

	local assertion = testResult:getAssertions()
	local errors = testResult:getTotalErrors()
	local passes = testResult:getPassed()
	local skips = testResult:getSkipped()

	_wraptest(
		pass,
		msg,
		{
			reason = _fmt(
				"Expected the test to %spass, but it did not.\n  Got %d assertion(s), %d passes(s), %d error(s), %d skip(s))",
				strictadverp,
				assertion,
				passes,
				errors,
				skips
			),
		}
	)
end

function glunatest.assert_testresult_not_passed(testResult, strict, msg)
	if strict == nil then
		strict = true
	end

	local pass = false
	local strictadverp = ""

	if strict then
		pass = testResult:hasPassedStrict()
		strictadverp = "STRICTLY "
	else
		pass = testResult:hasPassed()
	end

	local assertion = testResult:getAssertions()
	local errors = testResult:getTotalErrors()
	local passes = testResult:getPassed()
	local skips = testResult:getSkipped()

	_wraptest(
		not pass,
		msg,
		{
			reason = _fmt(
				"Expected the test not to %spass, but it did. Got %d assertion(s), %d pass(es), %d error(s), %d skip(s))",
				strictadverp,
				assertion,
				passes,
				errors,
				skips
			),
		}
	)
end

local asserttestlist = {
	["totalpasses"] = {
		getter = "getTotalPassed",
		reasonIs = "Expected the test to result in a total passed count of %d, but got %d",
		reasonNot = "Expected the test not to result in a total passed count of %d, but got %d",
	},

	["totalerrors"] = {
		getter = "getTotalErrors",
		reasonIs = "Expected the test to result in a total error count of %d, but got %d",
		reasonNot = "Expected the test not to result in a total error count of %d, but got %d",
	},

	["assertions"] = {
		getter = "getAssertions",
		reasonIs = "Expected the test to have exactly %d assertion(s), but got %d",
		reasonNot = "Expected the test not to have exactly %d assertion(s), but got %d",
	},

	["passes"] = {
		getter = "getPassed",
		reasonIs = "Expected the test to have exactly %d pass(es), but got %d",
		reasonNot = "Expected the test not to have exactly %d pass(es), but got %d",
	},

	["skips"] = {
		getter = "getSkipped",
		reasonIs = "Expected the test to have exactly %d skip(s), but got %d",
		reasonNot = "Expected the test not to have exactly %d skip(s), but got %d",
	},

	["failures"] = {
		getter = "getFailed",
		reasonIs = "Expected the test to have exactly %d failure(s), but got %d",
		reasonNot = "Expected the test not to have exactly %d failure(s), but got %d",
	},

	["errors"] = {
		getter = "getErrors",
		reasonIs = "Expected the test to have exactly %d error(s), but got %d",
		reasonNot = "Expected the test not to have exactly %d error(s), but got %d",
	},

	["exitcode"] = {
		getter = "getExitcode",
		reasonIs = "Expected the test to exit with code %d, it did with code %d",
		reasonNot = "Expected the test not to exit with code %d, it did with code %d",
	},
}

for name, v in pairs(asserttestlist) do
	local getter = v.getter
	local reasonIs = v.reasonIs
	local reasonNot = v.reasonNot

	glunatest["assert_testresult_equal_" .. name] = function(expected, testResult)
		local got = testResult[getter](testResult)

		_wraptest(
			got == expected,
			msg,
			{
				reason = _fmt(reasonIs, expected, got),
			}
		)
	end

	glunatest["assert_testresult_not_equal_" .. name] = function(expected, testResult)
		local got = testResult[getter](testResult)

		_wraptest(
			got ~= expected,
			msg,
			{
				reason = _fmt(reasonNot, expected, got),
			}
		)
	end
end


local asserttestlist = {
	["assertions"] = {
		hasser = "hasAssertions",
		getter = "getAssertions",
		reasonHas = "Expected the test to have %d assertion(s), but got no assertions",
		reasonHasNot = "Expected the test to have no assertions, but got %d assertion(s)",
	},

	["skips"] = {
		hasser = "hasSkipped",
		getter = "getSkipped",
		reasonHas = "Expected the test to have %d skip(s), but got no skips",
		reasonHasNot = "Expected the test to have no skips, but got %d skip(s)",
	},
}

for name, v in pairs(asserttestlist) do
	local getter = v.getter
	local hasser = v.hasser
	local reasonHas = v.reasonHas
	local reasonHasNot = v.reasonHasNot

	glunatest["assert_testresult_has_" .. name] = function(testResult)
		local has = testResult[hasser](testResult)
		local got = testResult[getter](testResult)

		_wraptest(
			has,
			msg,
			{
				reason = _fmt(reasonHas, got),
			}
		)
	end

	glunatest["assert_testresult_has_not_" .. name] = function(testResult)
		local has = testResult[hasser](testResult)
		local got = testResult[getter](testResult)

		_wraptest(
			not has,
			msg,
			{
				reason = _fmt(reasonHasNot, got),
			}
		)
	end
end

local function getDiff(exp, got, reasonPrefix)
	reasonPrefix = tostring(reasonPrefix)

	if exp == got then
		return true, reasonPrefix
	end

	local exptype = type(exp)
	local gottype = type(got)

	local expstr = tostring(exp)
	local gotstr = tostring(got)

	local tablemode = (exptype == "table" or gottype == "table")

	local diffmode = (
		tablemode or (
			exptype == "string" or gottype == "string"
		)
	)

	if exptype ~= gottype or not diffmode then
		local reason = _fmt(
			"%s\nExpected '%s' (type: %s), but got '%s' (type: %s)",
			reasonPrefix,
			libString:LimitString(expstr, 30),
			exptype,
			libString:LimitString(gotstr, 30),
			gottype
		)

		reason = string.Trim(reason)
		return false, reason
	end

	if expstr == gotstr then
		return true, reasonPrefix
	end

	if tablemode then
		exp = libTable:ToString(exp)
		got = libTable:ToString(got)

		exp = string.Replace(exp, "\t", "    ")
		got = string.Replace(got, "\t", "    ")
	else
		exp = libString:ReplaceWhiteSpace(exp)
		got = libString:ReplaceWhiteSpace(got)
	end

	local result = libString:Diff(exp, got)
	local config = LIB:GetConfig("properties") or {}

	local differences, errordiffblocks, errordiffhiddenblocks = libPrint:ProcessDiffResult(result, config.diff_output)

	local legend = libPrint:ProcessDiffResultLegend(differences, "--- Expected\n+++ Actual")

	local reason = _fmt(
		"%s\n%s\n\n%s",
		reasonPrefix,
		legend,
		differences
	)

	reason = string.Trim(reason)
	reason = reason .. "\n\n "

	return errordiffblocks <= 0, reason
end

function glunatest.assert_equal_bytes(exp, got, msg)
	local issame = exp == got

	if issame then
		_wraptest(
			true,
			msg,
			{
				reason = "",
			}
		)

		return
	end

	local exptype = type(exp)
	local gottype = type(got)

	local expstr = tostring(exp)
	local gotstr = tostring(got)
	local reasonPrefix = "Failed asserting that two strings are equal to the byte."

	if exptype ~= gottype then
		local reason = _fmt(
			"%s\nExpected '%s' (type: %s), but got '%s' (type: %s)",
			reasonPrefix,
			libString:LimitString(expstr, 30),
			exptype,
			libString:LimitString(gotstr, 30),
			gottype
		)

		_wraptest(
			issame,
			msg,
			{
				reason = reason,
			}
		)

		return
	end

	expstr = libString:ToHex(expstr)
	gotstr = libString:ToHex(gotstr)

	local config = LIB:GetConfig("properties") or {}

	expstr = libPrint:ProcessHexResult(expstr, "Expected:", config.hex_output)
	gotstr = libPrint:ProcessHexResult(gotstr, "Got:", config.hex_output)

	local reason = reasonPrefix .. "\n\n" .. libString:SideBySide("    ", "", expstr, gotstr)
	reason = reason .. "\n\n "

	_wraptest(
		issame,
		msg,
		{
			reason = reason,
		}
	)
end

function glunatest.assert_equal_ex(exp, got, msg)
	local issame = libTable:Compare(exp, got)

	if issame then
		_wraptest(
			true,
			msg,
			{
				reason = "",
			}
		)

		return
	end

	local issame, reason = getDiff(exp, got, "Failed asserting that two variables are equal.")

	_wraptest(
		issame,
		msg,
		{
			reason = reason,
		}
	)
end

function glunatest.assert_not_equal_ex(exp, got, msg)
	local issame = libTable:Compare(exp, got)

	if not issame then
		_wraptest(
			true,
			msg,
			{
				reason = "",
			}
		)

		return
	end

	local exptype = type(exp)

	local expstr = exp

	if exptype == "table" then
		expstr = libTable:ToString(expstr)
		expstr = string.Replace(expstr, "\t", "    ")
	else
		expstr = tostring(expstr)
		expstr = libString:ReplaceWhiteSpace(expstr)
	end

	expstr = libPrint:ProcessEqualResult(expstr)

	local legend = libPrint:ProcessDiffResultLegend(expstr, "")
	local reason = ""

	if legend == "" then
		reason = _fmt(
			"Expected something other than value (type: %s):\n\n%s",
			exptype,
			expstr
		)
	else
		reason = _fmt(
			"Expected something other than value (type: %s):\n%s\n\n%s",
			exptype,
			legend,
			expstr
		)
	end

	reason = string.Trim(reason)
	reason = reason .. "\n\n "

	_wraptest(
		not issame,
		msg,
		{
			reason = reason,
		}
	)
end

function glunatest.assert_path(got)
	local pathobj = libFile:ResolvePath(got, defaultmount)

	_wraptest(
		pathobj ~= nil,
		msg,
		{
			reason = _fmt("Expected a valid path object, got '%s'", tostring(got)) ,
		}
	)

end

function glunatest.assert_not_path(got)
	local pathobj = libFile:ResolvePath(got, defaultmount)

	_wraptest(
		pathobj == nil,
		msg,
		{
			reason = _fmt("Expected something other than a valid path object, got '%s'", tostring(pathobj)) ,
		}
	)

end

function glunatest.assert_path_equal(exp, got, defaultmount, msg)
	local pathobjExp = libFile:ResolvePath(exp, defaultmount)
	local pathobjGot = libFile:ResolvePath(got, defaultmount)
	local format = "Expected path:\n    %s\n  got:\n    %s"


	if pathobjExp and pathobjGot then
		_wraptest(
			pathobjExp == pathobjGot,
			msg,
			{
				reason = _fmt(format, tostring(pathobjExp), tostring(pathobjGot)) ,
			}
		)

		return
	end

	_wraptest(
		pathobjExp and pathobjGot and pathobjExp == pathobjGot,
		msg,
		{
			reason = _fmt(format, tostring(exp), tostring(got)) ,
		}
	)
end

function glunatest.assert_path_not_equal(exp, got, defaultmount, msg)
	local pathobjExp = libFile:ResolvePath(exp, defaultmount)
	local pathobjGot = libFile:ResolvePath(got, defaultmount)

	_wraptest(
		pathobjExp ~= pathobjGot,
		msg,
		{
			reason = _fmt("Expected other path than: \n  %s", tostring(exp)) ,
		}
	)
end

function glunatest.async(callback)
	assert(isfunction(callback), "bad argument #1, expected function")
	return libCoroutine:GetSyncObject(callback, 2)
end

function glunatest.async_yield(time)
	return libCoroutine:Yield(time or 0)
end

function glunatest.add_tests_by_callback(suite, name, dataProviderCallback, testFunction)
	assert(istable(suite), "bad argument #1, expected table")
	local i = 1

	name = libString:SanitizeFunctionName(name)
	name = "test_" .. name

	while true do
		local thisindex = i
		local data, suffix = dataProviderCallback(thisindex)
		if data == nil then
			return i - 1
		end

		suffix = string.Trim(tostring(suffix or ""))

		if suffix == "" then
			suffix = thisindex
		end

		suffix = libString:SanitizeFunctionName(suffix)

		local funcname = name .. "_" .. suffix

		suite[funcname] = function()
			testFunction(data, thisindex)
		end

		i = i + 1
	end
end

function glunatest.add_tests_by_table(suite, name, dataTable, testFunction)
	assert(istable(suite), "bad argument #1, expected table")
	local i = 1

	name = libString:SanitizeFunctionName(name)
	name = "test_" .. name

	local iterator = pairs
	local isSequential = table.IsSequential(dataTable)

	if isSequential then
		iterator = ipairs
	end

	for key, data in iterator(dataTable) do
		local thisindex = i
		local suffix = ""

		if isSequential then
			suffix = thisindex
		else
			suffix = string.Trim(tostring(key))

			if suffix == "" then
				suffix = thisindex
			end
		end

		suffix = libString:SanitizeFunctionName(suffix)

		local funcname = name .. "_" .. suffix

		suite[funcname] = function()
			testFunction(key, data, thisindex)
		end

		i = i + 1
	end

	return i - 1
end

function glunatest.mock_global_function(name)
	libMock:SetMockENV(glunatest.TESTENV)

	local mock = libMock:MockGlobalFunction(name)
	return mock
end

function glunatest.unmock_global_function(name)
	return libMock:UnmockGlobalFunction(name)
end

function glunatest.unmock_all_global_functions(name)
	return libMock:UnmockAllGlobalFunctions(name)
end

GLUNATEST = glunatest
