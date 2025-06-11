AddCSLuaFile()

local string = string
local rawget = rawget
local tostring = tostring
local error = error
local isfunction = isfunction
local istable = istable

local string_format = string.format

local LIB = {}

LIB.NAME = "glunatest"
LIB.TITLE = "GLunaTest"
LIB.DATAPATH = LIB.NAME
LIB.LUAPATH = LIB.NAME
LIB.STATIC_DATAPATH = "data_static/" .. LIB.NAME

LIB.MAXNESTEDLEVEL = 16
LIB._LOADED = {}
LIB._READONLY = true
LIB._CONFIG = {}
LIB._READYQUEUE = {}

local g_nextFrameHookName = LIB.NAME .. "_nextFrame_onReady"

local function _callSafely(func)
	local err = nil

	xpcall(func, function(thisErr)
		err = tostring(thisErr or "")
	end)

	if err then
		if err == "" then
			err = "Unknown error!"
		end

		ErrorNoHalt(err .. "\n")
	end
end

function LIB:LoadLib(name)
	name = tostring(name or "")
	name = string.Trim(name)
	name = string.lower(name)

	name = string.StripExtension(name)

	name = string.gsub(name, "%.%.%/" , "")
	name = string.gsub(name, "%s+" , "_")
	name = string.gsub(name, "%c+" , "")
	name = string.gsub(name, "[^%w_%-%/]" , "-")

	if self._LOADED[name] then
		return self._LOADED[name]
	end

	self._LOADED[name] = {
		name = name,
		lib = nil
	}

	local lib = self:Load("lib/" .. name)
	self._LOADED[name].lib = lib

	lib.NAME = name
	lib.GetName = function(this)
		return this.NAME
	end

	if isfunction(lib.Load) then
		_callSafely(function()
			lib:Load(self)
		end)
	end

	return self._LOADED[name]
end

function LIB:Load(path)
	path = tostring(path or "")
	path = string.Trim(path)

	path = self.LUAPATH .. "/" .. path
	path = string.lower(path)

	path = string.StripExtension(path)

	path = string.gsub(path, "%.%.%/" , "")
	path = string.gsub(path, "%s+" , "_")
	path = string.gsub(path, "%c+" , "")
	path = string.gsub(path, "[^%w_%-%/]" , "-")

	path = path .. ".lua"

	local lib = include(path)

	if not istable(lib) then
		return lib
	end

	lib.LIB = self
	lib.READY = false
	lib.PATH = path

	lib.GetLib = function(this)
		return this.LIB
	end

	lib.GetPath  = function(this)
		return this.PATH
	end

	lib.IsReady = function(this)
		return this.READY
	end

	if isfunction(lib.FileLoad) then
		_callSafely(function()
			lib:FileLoad(self)
		end)
	end

	self._READYQUEUE[path] = lib

	local callReady = nil

	callReady = function()
		hook.Remove("InitPostEntity", g_nextFrameHookName)
		hook.Remove("PostRenderVGUI", g_nextFrameHookName)
		hook.Remove("Think", g_nextFrameHookName)

		if not self then
			return
		end

		if not self._READYQUEUE then
			return
		end

		for thispath, thislib in pairs(self._READYQUEUE) do
			if thislib.READY then
				self._READYQUEUE[thispath] = nil
				continue
			end

			thislib.READY = true

			if isfunction(thislib.Ready) then
				_callSafely(function()
					thislib:Ready(self)
				end)
			end

			self._READYQUEUE[thispath] = nil
		end
	end

	hook.Remove("Think", g_nextFrameHookName)
	hook.Remove("PostRenderVGUI", g_nextFrameHookName)
	hook.Remove("InitPostEntity", g_nextFrameHookName)

	hook.Add("Think", g_nextFrameHookName, callReady)
	hook.Add("PostRenderVGUI", g_nextFrameHookName, callReady)
	hook.Add("InitPostEntity", g_nextFrameHookName, callReady)

	return lib
end

function LIB:GetColor(...)
	local ColorLib = self.color
	return ColorLib:GetColor(...)
end

function LIB:CreateObj(...)
	local ClassLib = self.class
	return ClassLib:CreateObj(...)
end

function LIB:GetName()
	return self.NAME
end

function LIB:GetTitle()
	return self.TITLE
end

function LIB:GetDataPath()
	return self.DATAPATH
end

function LIB:GetStaticDataPath()
	return self.STATIC_DATAPATH
end

function LIB:GetLuaPath()
	return self.LUAPATH
end

function LIB:GetMaxNestedTestLevel()
	return self.MAXNESTEDLEVEL
end

function LIB:CreateGLunaTestInstance()
	return self:Load("lunatest_emulator")
end

function LIB:CreateGLunaTestSetupInstance()
	return self:Load("setup")
end

local tableLib = nil
local luaLib = nil

local g_configcache = nil
local g_last_glunatest = nil

function LIB:Init()
	tableLib = self.table
	luaLib = self.lua

	luaLib:AddCSLuaFolder("SELFLUA:/lib")
	luaLib:AddCSLuaFiles({
		"SELFLUA:/setup.lua",
		"SELFLUA:/lunatest_emulator.lua",
	})

	table.Empty(self._LOADED)
	table.Empty(self._READYQUEUE)
	table.Empty(self._CONFIG)

	g_configcache = nil
	g_last_glunatest = nil

	local configLib = self.config
	local printLib = self.print
	local configfile = "config.txt"

	configLib:LoadConfigFiles(configfile, CLIENT, function(config, err)
		if err then
			printLib:warn(err)
			return
		end

		g_configcache = nil
		g_last_glunatest = nil

		tableLib:Merge(self._CONFIG, config or {}, true)
	end)

	self:LoadLib("system")
	self:LoadLib("debug")
	self:LoadLib("simplediff")

	self.simplediff.table_join = self.coroutine:AddYieldToFunction(self.simplediff.table_join, self.coroutine.YIELD_TIME_SHORT)
	self.simplediff.table_subtable = self.coroutine:AddYieldToFunction(self.simplediff.table_subtable, self.coroutine.YIELD_TIME_SHORT)
	self.simplediff.diff = self.coroutine:AddYieldToFunction(self.simplediff.diff, self.coroutine.YIELD_TIME_SHORT)

	self:LoadLib("file")
	self:LoadLib("cli")

	self:LoadLib("memory")
	self:LoadLib("net")
	self:LoadLib("mock")
	self:LoadLib("class")
end

local function buildconfig(thisconfig)
	local glunatest = _G.GLUNATEST

	if glunatest and g_last_glunatest ~= glunatest then
		g_configcache = nil
	end

	g_last_glunatest = glunatest

	if g_configcache then
		return g_configcache
	end

	local config = {}
	glunatest = glunatest or {}

	config = tableLib:Merge(config, thisconfig or {}, true)

	config.properties = config.properties or {}
	config.properties = tableLib:Merge(config.properties, glunatest.CONFIG or {}, true)

	g_configcache = config
	return config
end

function LIB:GetConfig(...)
	local config = buildconfig(self._CONFIG)

	local keys = {...}
	local lasti = #keys

	for i, key in ipairs(keys) do
		if not istable(config) and i < lasti then
			return nil
		end

		config = config[key]

		if config == nil then
			return nil
		end
	end

	return config
end

function LIB:Unload()
	hook.Remove("Think", g_nextFrameHookName)
	hook.Remove("PostRenderVGUI", g_nextFrameHookName)
	hook.Remove("InitPostEntity", g_nextFrameHookName)

	for k, v in pairs(self._LOADED) do
		local lib = v.lib

		if not istable(lib) then
			continue
		end

		if not isfunction(lib.Unload) then
			continue
		end

		local err = nil

		xpcall(function()
			lib:Unload(self)
		end, function(thisErr)
			err = tostring(thisErr or "")
		end)

		if err then
			if err == "" then
				err = "Unknown error!"
			end

			ErrorNoHalt(err .. "\n")
		end
	end

	for k, v in pairs(self._LOADED) do
		if not istable(v.lib) then
			continue
		end

		table.Empty(v.lib)
		self._LOADED[k] = v
	end

	for k, v in pairs(self._LOADED) do
		v.lib = nil
		self._LOADED[k] = v
	end

	hook.Remove("Think", g_nextFrameHookName)
	hook.Remove("PostRenderVGUI", g_nextFrameHookName)
	hook.Remove("InitPostEntity", g_nextFrameHookName)

	table.Empty(self._LOADED)
	table.Empty(self._READYQUEUE)
	table.Empty(self._CONFIG)

	collectgarbage("collect")
end


LIB = setmetatable(LIB, {
	-- Autoloader
	__index = function(this, key)
		local value = rawget(this, key)
		local loadLib = rawget(this, "LoadLib")

		if value ~= nil then
			return value
		end

		if not isfunction(loadLib) then
			return nil
		end

		value = loadLib(this, key)

		if not value then
			return nil
		end

		if not value.lib then
			return nil
		end

		return value.lib
	end,

	-- Readonly
	__newindex = function(this, key, value)
		local name = rawget(this, "TITLE")
		local readonly = rawget(this, "_READONLY")

		if not readonly then
			rawset(this, key, value)
		end

		error(string_format("%s[%s] can't be set. The library is readonly.", name, key))
	end,
})

return LIB
