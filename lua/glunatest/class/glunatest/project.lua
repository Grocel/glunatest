local libString = nil
local libTable = nil
local libPrint = nil
local libTimer = nil
local libConfig = nil
local libColor = nil
local libClass = nil
local libMemory = nil
local libLua = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "network/base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()

	libString = classLib.LIB.string
	libTable = classLib.LIB.table
	libPrint = classLib.LIB.print
	libTimer = classLib.LIB.timer
	libConfig = classLib.LIB.config
	libColor = classLib.LIB.color
	libClass = classLib.LIB.class
	libMemory = classLib.LIB.memory
	libLua = classLib.LIB.lua
end

function CLASS:Create()
	BASE.Create(self)
end

function CLASS:Remove()
	BASE.Remove(self)
end

function CLASS:SetTestSuites(testSuites)
	self._testSuites = {}
	self:AddTestSuites(testSuites)
end

function CLASS:AddTestSuites(testSuites)
	testSuites = testSuites or {}

	for i, v in ipairs(testSuites) do
		self:AddTestSuite(v)
	end
end

function CLASS:AddTestSuite(filename)
	filename = libLua:ResolvePath(filename)
	local index = filename:GetVirtualString()

	self._testSuites = self._testSuites or {}
	self._testSuitesIndex = self._testSuitesIndex or {}

	if self._testSuitesIndex[index] then
		return
	end

	self._testSuites[#self._testSuites + 1] = filename
	self._testSuitesIndex[index] = true
end

function CLASS:GetTestSuites()
	return libTable:Copy(self._testSuites or {})
end

function CLASS:SetEmulatorHelpers(emulatorHelpers)
	self._emulatorHelpers = {}
	self:AddEmulatorHelpers(emulatorHelpers)
end

function CLASS:AddEmulatorHelpers(emulatorHelpers)
	emulatorHelpers = emulatorHelpers or {}

	for i, v in ipairs(emulatorHelpers) do
		self:AddEmulatorHelper(v)
	end
end

function CLASS:AddEmulatorHelper(filename)
	filename = libLua:ResolvePath(filename)
	local index = filename:GetVirtualString()

	self._emulatorHelpers = self._emulatorHelpers or {}
	self._emulatorHelpersIndex = self._emulatorHelpersIndex or {}

	if self._emulatorHelpersIndex[index] then
		return
	end

	self._emulatorHelpers[#self._emulatorHelpers + 1] = filename
	self._emulatorHelpersIndex[index] = true
end

function CLASS:GetEmulatorHelpers()
	return libTable:Copy(self._emulatorHelpers or {})
end

function CLASS:SetProperties(properties)
	properties = properties or {}
	self.properties = properties
end

function CLASS:SetProperty(name, value)
	self.properties = self.properties or {}
	self.properties[name] = value
end

function CLASS:GetProperties()
	return libTable:Copy(self.properties or {})
end

function CLASS:GetProperty(name)
	local properties = self:GetProperties()
	return properties[name]
end

function CLASS:GetCSLUANamespace()
	local name = libString:SanitizeName(self:GetName())
	return "clientlua-" .. name
end

function CLASS:SetCSLua(clientLuaConfig)
	local namespace = self:GetCSLUANamespace()
	clientLuaConfig = clientLuaConfig or {}

	libLua:AddCSDownloadLuaFiles(clientLuaConfig.files or {}, namespace)
	libLua:AddCSDownloadLuaFolders(clientLuaConfig.folders or {}, namespace)
end

function CLASS:DownloadCSDownloadLuaFiles(callbackDone, callbackFileDone, progressCallback)
	local namespace = self:GetCSLUANamespace()

	libLua:DownloadCSDownloadLuaFiles(namespace, callbackDone, callbackFileDone, progressCallback)
end

return CLASS
