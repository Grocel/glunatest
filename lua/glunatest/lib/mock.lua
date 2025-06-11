local libTable = nil
local libClass = nil

local LIB = {}
local g_G = _GLunaTestLib_GetRootGlobal()
local g_GForMock = nil

local assert = g_G.assert
local error = g_G.error
local unpack = g_G.unpack
local IsValid = g_G.IsValid
local pairs = g_G.pairs
local ipairs = g_G.ipairs
local type = g_G.type
local isfunction = g_G.isfunction
local isstring = g_G.isstring
local isnumber = g_G.isnumber
local istable = g_G.istable
local tostring = g_G.tostring
local tonumber = g_G.tonumber
local setmetatable = g_G.setmetatable

local table = g_G.table
local math = g_G.math
local string = g_G.string

local table_concat = table.concat
local table_Copy = table.Copy
local string_format = string.format
local string_Explode = string.Explode
local math_floor = math.floor

local FUNCTIONS_BLACKLIST = {}
local FUNCTIONS_BLACKLIST_NAMES = {
	"assert",
	"error",
	"Error",
	"ErrorNoHalt",
	"print",
	"Msg",
	"MsgN",
	"MsgC",
	"getfenv",
	"setfenv",
	"FindMetaTable",
	"getmetatable",
	"setmetatable",
	"rawequal",
	"rawget",
	"rawset",
	"require",
	"include",
	"AddCSLuaFile",
	"xpcall",
	"pcall",
}

function LIB:Load(lib)
	libTable = lib.table
	libClass = lib.class
end

LIB._register = {}

function LIB:ParseName(name)
	if istable(name) then
		return name
	end

	name = tostring(name or "")
	local name = string_Explode(".", name, false)

	return name
end

function LIB:UnParseName(name)
	if not istable(name) then
		name = tostring(name or "")

		return name
	end

	name = table_concat(name, ".")
	return name
end

function LIB:GetByName(name)
	local nameData = self:ParseName(name)
	if not nameData then
		return nil
	end

	local value = g_GForMock

	for i, v in ipairs(nameData) do
		v = tostring(v or "")

		value = value[v]
		if value == nil then
			return nil
		end
	end

	return value
end

function LIB:SetByName(name, value)
	local nameData = libTable:Copy(self:ParseName(name))
	if not nameData then
		return false
	end

	local lastelementname = nameData[#nameData]
	nameData[#nameData] = nil

	local lasttable = self:GetByName(nameData)

	assert(istable(lasttable), string_format("lasttable is not a table, a %s value", type(lasttable)))

	lasttable[lastelementname] = value
	return self:GetByName(name) == value
end

function LIB:SetMockENV(G)
	g_GForMock = G

	FUNCTIONS_BLACKLIST = {}

	for k, name in pairs(FUNCTIONS_BLACKLIST_NAMES) do
		local func = g_G[name]

		if func then
			FUNCTIONS_BLACKLIST[func] = true
		end

		local func = g_GForMock[name]

		if func then
			FUNCTIONS_BLACKLIST[func] = true
		end
	end


	for k, func in pairs(g_G.debug) do
		FUNCTIONS_BLACKLIST[func] = true
	end

	for k, func in pairs(g_GForMock.debug) do
		FUNCTIONS_BLACKLIST[func] = true
	end
end

function LIB:MockGlobalFunction(name)
	local name = self:ParseName(name)
	local nameString = self:UnParseName(name)

	local func = nil

	if self._register[nameString] and self._register[nameString].func then
		func = self._register[nameString].func
	else
		func = self:GetByName(name)
	end

	assert(isfunction(func), string_format("the value '%s' is not a function", nameString))
	assert(not FUNCTIONS_BLACKLIST[func], string_format("the function '%s' is not allowed to be mocked", nameString))

	if self._register[nameString] and IsValid(self._register[nameString].mockHandler) then
		self._register[nameString].mockHandler:Remove()
	end

	self._register[nameString] = {func = func}

	local mockHandler = libClass:CreateObj("mock_handler", self, nameString)

	assert(IsValid(mockHandler), string_format("mockHandler for function '%s' could not be created", nameString))

	local newFunc = function(...)
		if not IsValid(mockHandler) then
			error('invalid mockHandler')
		end

		return mockHandler:Handle(...)
	end

	local done = self:SetByName(name, newFunc)
	assert(done, string_format("the function '%s' could not be mocked", nameString))

	self._register[nameString].mockHandler = mockHandler
	return mockHandler
end

function LIB:UnmockGlobalFunction(name)
	local name = self:ParseName(name)
	local nameString = self:UnParseName(name)
	local registeritem = self._register[nameString]

	if not registeritem then
		return false
	end

	if not registeritem.func then
		return false
	end

	local done = self:SetByName(name, registeritem.func)

	if not done then
		return false
	end

	registeritem.func = nil

	if IsValid(registeritem.mockHandler) then
		registeritem.mockHandler:Remove()
	end

	if registeritem.mockHandler then
		registeritem.mockHandler = nil
	end

	self._register[nameString] = nil
	return true
end

function LIB:UnmockAllGlobalFunctions()
	for k, v in pairs(self._register) do
		self:UnmockGlobalFunction(k)
	end
end


return LIB
