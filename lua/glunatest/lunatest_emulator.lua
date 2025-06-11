local libString = nil
local libTable = nil
local libPrint = nil
local libCoroutine = nil
local libCode = nil
local libDebug = nil
local libFile = nil
local libLua = nil
local libClass = nil

local LIB = {}
LIB._emulatorHelpersIndex = {}
LIB._emulatorHelpers = {}
LIB._includedFiles = {}

LIB._output_buffer = {}
LIB._output_summery = nil
LIB._testlevel = 0
LIB._runs = false
LIB._shouldprint = true
LIB._asynchronous = true

local G = _GLunaTestLib_GetRootGlobal()
local getfenvOriginal = G.getfenv

function LIB:FileLoad(lib)
	libString = lib.string
	libTable = lib.table
	libPrint = lib.print
	libCoroutine = lib.coroutine
	libCode = lib.code
	libDebug = lib.debug
	libFile = lib.file
	libLua = lib.lua
	libClass = lib.class
end

function LIB:IsRunning()
	return self._runs or false
end

function LIB:IsAsynchronous()
	return self._asynchronous or false
end

function LIB:SetAsynchronous(value)
	if self._runs then
		return false
	end

	self._asynchronous = value or false
	return true
end

function LIB:EnablePrint(enable)
	if self._runs then
		return false
	end

	--self._shouldprint = enable or false
	return true
end

function LIB:IsPrintEnabled(enable)
	return self._shouldprint or false
end

function LIB:_dynamicInclude(lua, env, dontStopOnError)
	setfenv(1, getfenvOriginal(2))

	local err = ""

	lua = libLua:ResolvePath(lua)
	local luaName = lua:GetRealString()

	local status, output = xpcall(function()
		setfenv(1, getfenvOriginal(2))

		if not libLua:Exists(lua) then
			error("Couldn't include file '" .. luaName .. "' (File not found)\n", 0)
		end

		local luaFile = libLua:Read(lua)

		if not luaFile then
			error("Couldn't include file '" .. luaName .. "' (File not readable)\n", 0)
		end

		local func = libLua:CompileCode(luaFile, luaName)

		return self:_CallInSandbox(func, env)
	end, function(thiserr)
		err = tostring(thiserr or "")
		err = string.Trim(err)
	end)

	if not status then
		if dontStopOnError then
			if err == "" then
				return nil
			end

			ErrorNoHalt(err .. "\n")
		else
			if err == "" then
				err = "Unknown error"
			end

			error(err .. "\n")
		end

		return nil
	end

	return output
end


local function createEnv(env)
	setfenv(1, getfenvOriginal(2))

	local thisGlobal = _G

	env = env or thisGlobal._tmpenv or {}
	env._G = env
	env._G._G = env
	env._tmpenv = env

	env = setmetatable(env, {
		__index = function(this, key)
			local value = rawget(this, key)

			if value ~= nil then
				return value
			end

			value = rawget(thisGlobal, key)
			return value
		end,
		__newindex = function(this, key, value)
			rawset(this, key, value)
		end
	})

	return env
end

local function removeUnwantedTestFunctions(env, isTestKeyCallback)

	-- remove functions that are from the original environment, so they aren't run as tests in the new environment
	for k, v in pairs(env) do
		if not isfunction(v) then
			continue
		end

		if not isTestKeyCallback(k) then
			continue
		end

		env[k] = nil
	end

	return env
end

function LIB:_CallInSandbox(func, env, ...)
	setfenv(1, getfenvOriginal(2))

	debug.setfenv(func, createEnv(env))

	return func(...)
end


function LIB:_OutputFunction(data, color, isdot, intest)
	data = tostring(data)
	isdot = isdot or false

	local buffer = self._output_buffer
	local level = self._testlevel

	if buffer then
		buffer[#buffer + 1] = data
	end

	if not intest and not isdot and not self._output_summery then
		self._output_summery = libString:ParseTestSummery(data)
	end

	if self._shouldprint then
		libPrint:PrintTestData(color, data, level, isdot, intest)
	end

	self:OnOutput(color, data, level, isdot, intest)
end

function LIB:_EmulatePrintDot()
	local colors = {
		["F"] = GLunaTestLib:GetColor("fail"),
		["E"] = GLunaTestLib:GetColor("error"),
		["W"] = GLunaTestLib:GetColor("warning"),
		["s"] = GLunaTestLib:GetColor("skip"),
		["."] = GLunaTestLib:GetColor("ok"),
	}

	local printDot = function(dot)
		dot = string.Trim(tostring(dot or "."))

		if dot == "" then
			dot = "."
		end

		local color = colors[dot]

		self:_OutputFunction(dot, color, true, false)
	end

	return printDot
end

function LIB:_EmulatePrint(intest)
	local newprint = function(...)
		local values = {...}

		for i, v in ipairs(values) do
			self:_OutputFunction(tostring(v) .. "\t", nil, false, intest)
		end

		self:_OutputFunction("\n", nil, false, intest)
	end

	return newprint
end

local oldrequire = require

function LIB:_EmulateRequire(env)
	local newrequire = function(name, ...)
		setfenv(1, getfenvOriginal(2))

		name = libFile:SanitizeFilename(name)

		if self._includedFiles[name] then
			return self._includedFiles[name]
		end

		if _G.GLUNATEST then
			if name == "lunatest" or name == "glunatest" then
				return _G.GLUNATEST
			end

			local execpath = GLUNATEST.PATH
			if execpath then
				local filename = execpath:Concat("/" .. name .. ".lua")

				if libLua:Exists(filename) then
					self._includedFiles[name] = self:_dynamicInclude(filename, env)

					return self._includedFiles[name]
				end
			end
		end

		local err = ""
		local status = xpcall(oldrequire, function(thiserr)
			err = tostring(thiserr or "")
			err = string.Trim(err)
		end, name, ...)

		if not status then
			error(err, 2)
		end

		return nil
	end

	return newrequire
end

function LIB:_loadTestLibrary(args, testenv, helpers)
	setfenv(1, getfenvOriginal(2))
	local thisGlobal = _G

	args = args or {}

	if not istable(args) then
		args = tostring(args or "")
		args = string.Split(args, " ")
	end

	local lt_arg = {}
	for k, v in pairs(args) do
		v = tostring(v or "")
		if v == "" then continue end

		lt_arg[#lt_arg + 1] = tostring(v or "")
	end

	testenv = createEnv(testenv)

	local env = createEnv({
		print = self:_EmulatePrint(false),
		printDot = self:_EmulatePrintDot(),
		require = self:_EmulateRequire(testenv),
		arg = lt_arg,
	})

	env.getfenv = function(level, ...)
		if isnumber(level) then
			if level >= 3 then
				return testenv
			end

			return getfenvOriginal(level + 1, ...)
		end

		return getfenvOriginal(level, ...)
	end

	env.package = {
		loaded = setmetatable({}, {
			__index = function(this, key)
				return env.require(key)
			end
		})
	}

	local lunatest = self:_dynamicInclude("SELFLUA:lunatest.lua", env)

	lunatest.TESTENV = testenv
	env.GLUNATEST = lunatest

	self:_dynamicInclude("SELFLUA:emulatorhelper/glunatest.lua", env)

	for i, filename in ipairs(helpers) do
		self:_dynamicInclude(filename, env)
	end

	return lunatest
end

function LIB:_CreateResultObject(exitcode, buffer, summery, filename, path, level, isasynchronous, args)
	summery = summery or {}

	local data = {
		exitcode = tonumber(exitcode or 0) or 0,
		buffer = tostring(buffer or ""),

		time = tonumber(summery.time or 0) or 0,
		assertions = tonumber(summery.assertions or 0) or 0,
		passed = tonumber(summery.passed or 0) or 0,
		failed = tonumber(summery.failed or 0) or 0,
		errors = tonumber(summery.errors or 0) or 0,
		skipped = tonumber(summery.skipped or 0) or 0,

		filename = tostring(filename or ""),
		path = tostring(path or ""),
		nestedLevel = tonumber(level or 0) or 0,
		isAsynchronous = isasynchronous or false,
		arguments = args or {},
	}

	local result = libClass:CreateObj("glunatest/result/test_result", self, data)
	return result
end

function LIB:RunTestSuite(filename, args, additionalVars, callback)
	setfenv(1, getfenvOriginal(2))

	local thisGlobal = _G
	local level = (thisGlobal.TESTLEVEL or 0) + 1

	if level > GLunaTestLib:GetMaxNestedTestLevel() then
		libPrint:errorf("Nested test stack overflow!")
	end

	if callback then
		assert(isfunction(callback) or istable(callback), "bad argument #4, expected a callable")
	else
		callback = (function() end)
	end

	filename = libLua:ResolvePath(filename)

	local helpers = libTable:Copy(self._emulatorHelpers)
	local isasynchronous = self._asynchronous

	local function run()
		local err
		local GLUNATEST

		local function runTest()
			local status = xpcall(function()
				if not libLua:Exists(filename) then
					libPrint:errorf("Can not run test '%s'. The file is missing.", 2, filename:GetRealString())
				end

				if self._runs then
					libPrint:errorf("The test '%s' is already running.", 2, filename:GetRealString())
				end

				self._runs = true
				self._testlevel = level

				self._includedFiles = {}
				self._output_buffer = {}
				self._output_summery = nil

				local env = libTable:Copy(thisGlobal)
				additionalVars = libTable:Copy(additionalVars or {})

				env.print = self:_EmulatePrint(true)
				env.require = self:_EmulateRequire(env)

				env.package = {
					loaded = setmetatable({}, {
						__index = function(this, key)
							return env.require(key)
						end
					})
				}

				env.TESTLEVEL = level

				GLUNATEST = self:_loadTestLibrary(args, env, helpers)

				env.GLUNATEST = GLUNATEST

				local path = libFile:GetPathFromFilename(filename)

				for k, v in pairs(additionalVars) do
					GLUNATEST[k] = v
				end

				GLUNATEST.MAINFILE = filename
				GLUNATEST.PATH = path
				GLUNATEST.TESTLEVEL = level
				GLUNATEST.ISASYNCHRONOUS = isasynchronous
				GLUNATEST._exit_code = nil

				env = removeUnwantedTestFunctions(env, GLUNATEST.is_test_key)

				self:_dynamicInclude(filename, env, true)
			end, function(thiserr)
				err = tostring(thiserr or "")
				err = string.Trim(err)
				err = libDebug:Traceback(err, 2)
			end)

			if status then
				err = nil
			end
		end

		local function postTest()
			local exitcode = 0

			local buffer = self._output_buffer
			self._output_buffer = {}

			local summery = self._output_summery
			self._output_summery = nil

			if GLUNATEST then
				exitcode = GLUNATEST._exit_code or 0

				GLUNATEST.MAINFILE = nil
				GLUNATEST.PATH = nil
				GLUNATEST.TESTLEVEL = nil
				GLUNATEST.ISASYNCHRONOUS = nil
				GLUNATEST._exit_code = nil

				for k, v in pairs(additionalVars) do
					GLUNATEST[k] = nil
				end
			end

			self._runs = false

			if self._coroutine then
				self._coroutine:Remove()
				self._coroutine = nil
			end

			buffer = table.concat(buffer)

			if callback then
				callback(self:_CreateResultObject(exitcode, buffer, summery, filename, path, level, isasynchronous, args))
			end

			if err then
				libPrint:warn(err)
			end
		end

		local parentThread = libCoroutine:GetThread()

		if isasynchronous then
			self._coroutine = libCoroutine:Create(runTest, parentThread, postTest)
			self._coroutine:SetSkippingYields(false)

			return
		end

		if parentThread then
			local oldIsSkippingYields = parentThread:IsSkippingYields()
			parentThread:SetSkippingYields(true)

			runTest()
			postTest()

			parentThread:SetSkippingYields(oldIsSkippingYields)
			return
		end

		runTest()
		postTest()
	end

	run()
	return true
end

function LIB:AddEmulatorHelper(filename)
	filename = libLua:ResolvePath(filename)

	self._emulatorHelpersIndex = self._emulatorHelpersIndex or {}

	if self._emulatorHelpersIndex[filename] then
		return true
	end

	self._emulatorHelpersIndex[filename] = true

	local emulatorHelpers = self._emulatorHelpers or {}
	emulatorHelpers[#emulatorHelpers + 1] = filename

	self._emulatorHelpers = emulatorHelpers

	return true
end

function LIB:AddEmulatorHelpers(filenames)
	if not istable(filenames) then
		filenames = {filenames}
	end

	for i, filename in ipairs(filenames) do
		self:AddEmulatorHelper(filename)
	end
end

function LIB:SetEmulatorHelpers(filenames)
	self:ClearEmulatorHelpers()
	self:AddEmulatorHelpers(filenames)
end

function LIB:ClearEmulatorHelpers()
	self._emulatorHelpersIndex = {}
	self._emulatorHelpers = {}
end

function LIB:OnOutput(color, data, level, isdot, intest)
	-- override me
end

return LIB
