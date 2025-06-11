local LIB = {}
local g_Classes = {}
local g_Globals = {}

local g_classID = 0
local g_instanceID = 0

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

function LIB:Load(lib)
end

function LIB:Unload(lib)
	g_Classes = {}
	g_Globals = {}
end

function LIB:SanitizeClassname(text)
	text = self.LIB.file:SanitizeFilename(text)
	text = string.gsub(text, "%.lua$", "", 1 )
	text = string.gsub(text, "%.", "-")

	return text
end

local g_metamethods = {
	"__add", -- x + y
	"__sub", -- x - y
	"__unm", -- -x
	"__mul", -- x * y
	"__div", -- x / y
	"__mod", -- x % y
	"__pow", -- x ^ y
	"__concat", -- x .. y

	"__eq", -- x == y
	"__lt", -- x < y, x >= y
	"__le", -- x <= y, x > y
	"__len", -- #x

	"__call", -- x()
	"__tostring", -- tostring(x)
	"__gc", -- garbage collection
}

local g_class_mt = {
	__index = function(this, index)
		local value = rawget(this, index)

		if value ~= nil then
			return value
		end

		local getClass = rawget(this, "GetClass")
		if not getClass then
			return nil
		end

		local class = getClass(this)
		if not class then
			return nil
		end

		value = class[index]
		if value ~= nil then
			return value
		end

		return value
	end,
}

for k,v in pairs(g_metamethods) do
	if rawget(g_class_mt, v) then
		continue
	end

	local func = function(this, ...)
		return this[v](this, ...)
	end

	rawset(g_class_mt, v, func)
end

local function enrichClass(new_class, baseClass)
	if baseClass ~= nil then
		setmetatable( new_class, {
			__index = baseClass,
		} )
	end

	local function getClassInternal(theClass)
		if istable(theClass) then
			local getClassname = rawget(theClass, "GetClassname")

			if isfunction(getClassname) then
				theClass = getClassname(theClass)
			end
		end

		theClass = tostring(theClass or "")
		theClass = g_Classes[theClass]

		if not theClass then
			return nil
		end

		return theClass
	end

	function new_class:new()
		local newinst = setmetatable({}, g_class_mt)

		function newinst:GetClass()
			return getClassInternal(new_class)
		end

		newinst.ID = g_instanceID
		g_instanceID = g_instanceID + 1

		return newinst
	end

	function new_class:GetID()
		return self.ID or 0
	end

	function new_class:GetClassname()
		return self.classname
	end

	function new_class:GetBaseClassname()
		local baseClass = self:GetBaseClass()
		if not baseClass then return end

		return baseClass:GetClassname()
	end

	function new_class:GetClassID()
		return self.classid
	end

	function new_class:GetBaseClassID()
		local baseClass = self:GetBaseClass()
		if not baseClass then return end

		return baseClass:GetClassID()
	end

	-- Return the class object of the instance
	function new_class:GetClass()
		return getClassInternal(new_class)
	end

	-- Return the super class object of the instance
	function new_class:GetBaseClass()
		return getClassInternal(baseClass)
	end

	-- Return true if the caller is an instance of theClass
	function new_class:isa(theClass)
		local curClass = self:GetClass()

		theClass = getClassInternal(theClass)

		if not theClass then
			return false
		end

		while curClass ~= nil do
			if curClass == theClass then
				return true
			end

			curClass = curClass:GetBaseClass()
		end

		return false
	end
end

function LIB:isa(classA, classB)
	if not classA then
		return false
	end

	if not classB then
		return false
	end

	classA = self:GetClass(classA)
	classB = self:GetClass(classB)

	if not classA then
		return false
	end

	if not classB then
		return false
	end

	return classA:isa(classB)
end


function LIB:GetClass(name)
	if istable(name) then
		if isfunction(name.GetClassname) then
			name = name:GetClassname()
		else
			name = ""
		end
	end

	name = self:SanitizeClassname(name)

	if name == "" then
		return nil
	end

	if g_Classes[name] then
		return g_Classes[name]
	end

	g_Classes[name] = nil

	local luaPath = self.LIB.LUAPATH .. "/class/" .. name .. ".lua";
	local luaName = "[CLASS: '" .. name .. "'] LUA:" .. luaPath

	local luaFile = file.Read(luaPath, "LUA")
	assert(luaFile, "Couldn't include file '" .. luaName .. "' (File not readable)")

	local CLASS = self.LIB.lua:RunCode(luaFile, luaName)
	assert(istable(CLASS), "Couldn't create class '" .. name .. "', an invalid class table was returned")

	g_Classes[name] = CLASS

	local parentname = self:SanitizeClassname(CLASS.baseClassname or "")
	CLASS.baseClassname = nil

	local baseClass = nil

	if parentname ~= "" and parentname ~= name then
		local loadError = nil

		local status, output = xpcall(function()
			baseClass = self:GetClass(parentname)
		end, function(thiserr)
			g_Classes[name] = nil

			loadError = tostring(thiserr or "")
			loadError = string.Trim(loadError)
		end)

		if loadError then
			error(loadError, 0)
		end
	end

	g_classID = g_classID + 1

	CLASS.classname = name
	CLASS.classid = g_classID

	enrichClass(CLASS, baseClass)

	CLASS.CreateObj = function(this, ...)
		return self:CreateObj(...)
	end

	CLASS.GetGlobalVar = function(this, key, fallback)
		key = tostring(key or "")

		local value = g_Globals[key]

		if value == nil then
			value = fallback
		end

		return value
	end

	CLASS.SetGlobalVar = function(this, key, value)
		key = tostring(key or "")

		g_Globals[key] = value
		return g_Globals[key]
	end

	g_Classes[name] = CLASS

	if isfunction(CLASS.ClassLoad) then
		_callSafely(function()
			CLASS:ClassLoad(self)
		end)
	end

	return CLASS
end

function LIB:CreateObj(classname, ...)
	local class = self:GetClass(classname)
	local obj = class:new()

	if obj.Create then
		obj:Create(...)
	end

	obj.Create = nil

	assert(IsValid(obj), "Couldn't create object of class '" .. classname .. "', an invalid object was returned")
	return obj
end

return LIB
