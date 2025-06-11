local libString = nil
local libTable = nil
local libPrint = nil
local libTimer = nil
local libConfig = nil
local libColor = nil
local libClass = nil
local libMemory = nil
local libNet = nil
local libLua = nil

local LIB = {}
LIB._glunatest = nil
LIB._runs = false

function LIB:FileLoad(lib)
	libString = lib.string
	libTable = lib.table
	libPrint = lib.print
	libTimer = lib.timer
	libConfig = lib.config
	libColor = lib.color
	libClass = lib.class
	libMemory = lib.memory
	libNet = lib.net
	libLua = lib.lua

	self:CreatePrepareDownloadReceiver()
end

function LIB:GetGLunaTest()
	if not self._glunatest then
		self._glunatest = GLunaTestLib:CreateGLunaTestInstance()
	end

	return self._glunatest
end

function LIB:GetProjects()
	if not IsValid(self._projectManager) then
		return {}
	end

	return self._projectManager:GetObjects()
end

function LIB:GetProjectByName(name)
	if not IsValid(self._projectManager) then
		return nil
	end

	name = libString:SanitizeName(name)
	return self._projectManager:Get(name)
end


function LIB:AddProject(name)
	if not self._projectManager then
		self._projectManager = libClass:CreateObj("object_manager/manager")
	end

	return self._projectManager:CreateManagedObj(name, "glunatest/project")
end

function LIB:IsRunning()
	return self._runs or false
end

function LIB:_CreateResultObject(results, projectName, args, properties)
	local data = {
		results = results or {},
		projectName = tostring(projectName or ""),
		arguments = args or {},
		properties = properties or {},
	}

	local result = libClass:CreateObj("glunatest/result/project_test_result", self, data)
	return result
end

function LIB:RunProjectTestSuites(project, args, callback, ply)
	local projectName = ""

	if isstring(project) then
		projectName = libString:SanitizeName(project)
		project = self:GetProjectByName(projectName)
	end

	if projectName == "" and project then
		projectName = project:GetName()
		projectName = libString:SanitizeName(projectName)
	end

	if not IsValid(project) then
		libPrint:errorf("Can not test project '%s'. It is not registered.", 2, projectName)
	end

	if not libClass:isa(project, "glunatest/project") then
		libPrint:errorf("Can not test project '%s'. Expected class 'glunatest/project', got class '%s' instead.", 2, projectName, project:GetClassname())
	end

	local testSuitesQueue = libClass:CreateObj("queue", project:GetTestSuites())

	if callback then
		assert(isfunction(callback) or istable(callback), "bad argument #4, expected function or table")
	else
		callback = (function() end)
	end

	if self._runs then
		libPrint:errorf("Can not test project '%s'. GLunaTest is already running tests.", 2, projectName)
	end

	local colDefault = libColor:GetColor("default")
	local colWarning = libColor:GetColor("warning")
	local colInfo = libColor:GetColor("info")
	local colOk = libColor:GetColor("ok")
	local colError = libColor:GetColor("error")

	local results = {}
	local index = 1

	local function RunTestSuite()
		local glunatest = self:GetGLunaTest()

		local emulatorHelpers = project:GetEmulatorHelpers()
		local properties = project:GetProperties()

		glunatest:ClearEmulatorHelpers()
		glunatest:AddEmulatorHelpers(emulatorHelpers)

		local testSuite = testSuitesQueue:PopLeft()
		index = index + 1

		if not testSuite then
			local result = self:_CreateResultObject(results, projectName, args, properties)

			local errorcount = result:getTotalErrors()
			local haserrors = result:hasErrors()
			local hasassertions = result:hasAssertions()

			libPrint:printcc(colDefault, "Test of project ")
			libPrint:printcc(colInfo, "'" .. projectName .. "'")
			libPrint:printcc(colDefault, ": ")

			if haserrors then
				libPrint:printcc(colError, string.format("Done, %d error(s).", errorcount))
			else
				if hasassertions then
					libPrint:printcc(colOk, "Done, no errors.")
				else
					libPrint:printcc(colWarning, "Done, no assertions.")
				end
			end

			libPrint:printcc("\n")

			self._runs = false
			libMemory:Cleanup()

			callback(result)
			return
		end

		local testSuitePath = testSuite:GetRealString()

		libPrint:printcc(colDefault, "  Test from file ")
		libPrint:printcc(colInfo, "'" .. testSuitePath .. "'")
		libPrint:printcc(colDefault, " from project ")
		libPrint:printcc(colInfo, "'" .. projectName .. "'")
		libPrint:printcc(colDefault, ": Start...")
		libPrint:printcc("\n")

		local run = glunatest:RunTestSuite(testSuite, args, {
			PROJECT = project,
			PLAYER = ply,
			CONFIG = properties,
		}, function(result)
			if not result then
				RunTestSuite()
				return
			end

			local errorcount = result:getTotalErrors()
			local haserrors = result:hasErrors()
			local hasassertions = result:hasAssertions()

			results[#results + 1] = result

			libPrint:printcc(colDefault, "  Test from file ")
			libPrint:printcc(colInfo, "'" .. testSuitePath .. "'")
			libPrint:printcc(colDefault, " from project ")
			libPrint:printcc(colInfo, "'" .. projectName .. "'")
			libPrint:printcc(colDefault, ": ")

			if haserrors then
				libPrint:printcc(colError, string.format("Done, %d error(s).", errorcount))
			else
				if hasassertions then
					libPrint:printcc(colOk, "Done, no errors.")
				else
					libPrint:printcc(colWarning, "Done, no assertions.")
				end
			end

			libPrint:printcc("\n")

			RunTestSuite()
		end)

		if not run then
			RunTestSuite()
			return
		end
	end

	libPrint:printcc(colDefault, "Test of project ")
	libPrint:printcc(colInfo, "'" .. projectName .. "'")
	libPrint:printcc(colDefault, ": Start...")
	libPrint:printcc("\n")

	self._runs = true

	if SERVER then
		RunTestSuite()
		return true
	end

	project:DownloadCSDownloadLuaFiles(function(ok, errors)
		if not ok then
			return
		end

		RunTestSuite()
	end, function(success, data, errors, bundleIndex, bundleCount)
		if not success then
			libPrint:printcc("\n")

			if bundleIndex then
				libPrint:printcc(colError, "  Error downloading file bundle ")
				libPrint:printcc(colInfo, string.format("%d/%d", bundleIndex, bundleCount))
				libPrint:printcc(colError, " for project ")
				libPrint:printcc(colInfo, string.format("'%s'", projectName))
				libPrint:printcc("\n")
			end

			for filename, err in pairs(errors) do
				if bundleIndex then
					libPrint:printcc(colError, "    - ")
					libPrint:printcc(colInfo, filename)
					libPrint:printcc(colError, ": ")
					libPrint:printcc(colError, err)
				else
					libPrint:printcc(colError, string.format("  Error downloading Lua file list for project '%s': %s", projectName, err))
				end

				libPrint:printcc("\n")
			end

			libPrint:printcc("\n")
			return
		end

		libPrint:printcc(colOk, "    Done")
		libPrint:printcc("\n")
		libPrint:printcc("\n")
	end, function(filenames, bundleIndex, bundleCount, data)
		local index = data.index
		local totalsize = data.totalsize

		if index ~= 1 then
			return
		end

		if not filenames then
			libPrint:printcc(colDefault, "  Downloading file list for project ")
			libPrint:printcc(colInfo, string.format("'%s'", projectName))
			libPrint:printcc("\n")
		else
			libPrint:printcc(colDefault, "  Downloading file bundle ")
			libPrint:printcc(colInfo, string.format("%d/%d", bundleIndex, bundleCount))
			libPrint:printcc(colDefault, " for project ")
			libPrint:printcc(colInfo, string.format("'%s'", projectName))
			libPrint:printcc("\n")

			for i, filename in ipairs(filenames) do
				libPrint:printcc(colDefault, "    - ")
				libPrint:printcc(colInfo, filename)
				libPrint:printcc("\n")
			end
		end

		libPrint:printcc(colDefault, "  Totalsize: ")
		libPrint:printcc(colInfo, string.NiceSize(totalsize))
		libPrint:printcc("\n")
	end)

	return true
end

function LIB:LoadConfig(callback)
	assert(isfunction(callback) or istable(callback), "bad argument #1, expected a callable")

	local configfile = "setup.txt"

	libConfig:LoadConfigs(configfile, function(config, err)
		if err then
			callback(false, err)
			return
		end

		if self._projectManager then
			self._projectManager:Remove()
			self._projectManager = nil
		end

		local globalTest = config.test or {}
		if not istable(globalTest) then
			globalTest = {globalTest}
		end

		local globalEmulatorHelper = config.emulatorhelper or {}
		if not istable(globalEmulatorHelper) then
			globalEmulatorHelper = {globalEmulatorHelper}
		end

		local globalProperties = config.properties or {}
		if not istable(globalProperties) then
			globalProperties = {globalProperties}
		end

		local globalClientLua = config.clientlua or {}
		if not istable(globalClientLua) then
			globalClientLua = {globalClientLua}
		end

		local projects = config.projects or {}

		for k, project in libTable:PrioritizedSortedPairs(projects, "priority") do
			local name = libString:SanitizeName(project.name)
			if name == "" then continue end

			local baseTest = libTable:Copy(globalTest)
			local test = project.test or {}
			if not istable(test) then
				test = {test}
			end

			test = libTable:Merge(baseTest, test)

			local baseEmulatorHelper = libTable:Copy(globalEmulatorHelper)
			local emulatorHelper = project.emulatorhelper or {}
			if not istable(emulatorHelper) then
				emulatorHelper = {emulatorHelper}
			end

			emulatorHelper = libTable:Merge(baseEmulatorHelper, emulatorHelper)

			local baseProperties = libTable:Copy(globalProperties)
			local properties = project.properties or {}
			if not istable(properties) then
				properties = {properties}
			end

			properties = libTable:Merge(baseProperties, properties)

			local baseClientLua = libTable:Copy(globalClientLua)
			local clientLua = project.clientlua or {}
			if not istable(clientLua) then
				clientLua = {clientLua}
			end

			clientLua = libTable:Merge(baseClientLua, clientLua)

			local project = self:AddProject(name)

			project:SetCSLua(clientLua)
			project:SetProperties(properties)

			for k, filename in libTable:PrioritizedSortedPairs(test, "priority") do
				if istable(filename) then
					filename = filename.file or ""
				end

				project:AddTestSuite(filename)
			end

			for k, filename in libTable:PrioritizedSortedPairs(emulatorHelper, "priority") do
				if istable(filename) then
					filename = filename.file or ""
				end

				project:AddEmulatorHelper(filename)
			end
		end

		libMemory:Cleanup()
		callback(true, nil)
	end)
end

function LIB:CreatePrepareDownloadReceiver()
	if not SERVER then
		return
	end

	local receiver = libNet:CreateReceiver("setup_download_prepare")

	receiver.OnReceive = function(this, stream, ply)
		self:LoadConfig(function(success, err)
			local streamToSend = libClass:CreateObj("stream")
			local sender = libNet:CreateSender("setup_download_prepared")

			streamToSend:WriteBool(success)
			streamToSend:WriteString(err)

			sender:Send(ply, streamToSend)
		end)
	end

	receiver.OnRemove = function(this)
		self:CreatePrepareDownloadReceiver()
	end

	return receiver
end

function LIB:PrepareDownload(callback)
	if not CLIENT then
		callback(true, nil)
		return
	end

	assert(isfunction(callback) or istable(callback), "bad argument #1, expected a callable")

	local receiver = libNet:CreateReceiver("setup_download_prepared")

	receiver.OnReceive = function(this, stream, ply)
		callback(stream:ReadBool(), stream:ReadString())
	end

	receiver.OnDone = function(this)
		this:Remove()
	end

	receiver.OnError = function(this, status, statusname)
		callback(false, string.format("Transmission error %d ('%s')", status, statusname))
	end

	receiver.OnTimeout = function(this)
		callback(false, "Transmission timeout")
	end

	receiver.OnCancel = function(this)
		callback(false, "Transmission canceled")
	end

	local sender = libNet:CreateSender("setup_download_prepare")

	sender.OnError = function(this, status, statusname)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(false, string.format("Transmission error %d ('%s')", status, statusname))
	end

	sender.OnTimeout = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(false, "Transmission timeout")
	end

	sender.OnCancel = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(false, "Transmission canceled")
	end

	sender:Send()
end


return LIB
