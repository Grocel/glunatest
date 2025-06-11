local libPrint = nil
local libJson = nil
local libTable = nil
local libFile = nil
local libClass = nil
local libNet = nil

local LIB = {}

function LIB:Load(lib)
	libPrint = lib.print
	libJson = lib.json
	libTable = lib.table
	libFile = lib.file
	libClass = lib.class
	libNet = lib.net
end

function LIB:Ready(lib)
	self:CreateReceiver()
end

function LIB:LoadConfigFile(filename, optional, defaultMount)

	local loaded = {}
	local cache = {}

	local loadfile = nil
	local runincluderecusive = nil

	runincluderecusive = function(t)
		if cache[t] then
			return t
		end

		for k, v in pairs(t) do
			if k == "include" then
				local incs = v

				if not istable(incs) then
					incs = {tostring(incs)}
				end

				t["include"] = nil

				for i, inc in pairs(incs) do
					local incvalues = loadfile(inc, false)

					t = libTable:Merge(t, incvalues)
				end

				continue
			end

			if istable(v) then
				t[k] = runincluderecusive(v)
				continue
			end
		end

		cache[t] = true
		return t
	end

	loadfile = function(thisfilename, isoptional)
		local path = libFile:ResolvePath(thisfilename, defaultMount)

		if loaded[path] then
			return loaded[path]
		end

		if not libFile:Exists(path) then
			if isoptional then
				return {}
			end

			libPrint:errorf("Config '%s' was not found", 1, path:GetRealString())
		end

		local config = libFile:Read(path)
		config = libJson:Decode(config)

		if not config then
			libPrint:errorf("Config '%s' is an invalid JSON file", 1, path:GetRealString())
		end

		loaded[path] = config
		config = runincluderecusive(config)
		loaded[path] = config

		return config
	end

	local config = loadfile(filename, optional)
	return config
end

function LIB:CreateReceiver()
	if not SERVER then
		return
	end

	local receiver = libNet:CreateReceiver("load_config")

	receiver.OnReceive = function(this, stream, ply)
		local count = stream:ReadUInt16()
		local files = {}

		for i = 1, count do
			files[#files + 1] = stream:ReadString()
		end

		self:LoadConfigFiles(files, true, function(config, err)
			local streamToSend = libClass:CreateObj("stream")
			local sender = libNet:CreateSender("load_config")

			streamToSend:WriteString(err)

			if config then
				streamToSend:WriteJson(config)
			end

			sender:Send(ply, streamToSend)
		end)
	end

	receiver.OnRemove = function(this)
		self:CreateReceiver()
	end

	return receiver
end

function LIB:LoadConfigFiles(filenames, forClient, callback)
	assert(isfunction(callback) or istable(callback), "bad argument #3, expected a callable")

	if not istable(filenames) or libClass:isa(filenames, "file/path") then
		filenames = {filenames}
	end

	local config = {}

	for i, filename in ipairs(filenames) do
		local err = nil

		local dataCommonStatic = nil
		local dataRealmStatic = nil

		local dataCommon = nil
		local dataRealm = nil

		local status = xpcall(function()
			dataCommonStatic = self:LoadConfigFile(filename, false, "CONFIG_STATIC")
			dataCommon = self:LoadConfigFile(filename, true, "CONFIG")

			dataRealmStatic = self:LoadConfigFile(filename, true, forClient and "CONFIG_CLIENT_STATIC" or "CONFIG_SERVER_STATIC")
			dataRealm = self:LoadConfigFile(filename, true, forClient and "CONFIG_CLIENT" or "CONFIG_SERVER")
		end, function(thiserr)
			err = tostring(thiserr or "")
			if err == "" then
				err = "Unknown error!"
			end
		end)

		if not status then
			callback(nil, err)
			return
		end

		libTable:Merge(config, dataCommonStatic or {}, true)
		libTable:Merge(config, dataRealmStatic or {}, true)
		libTable:Merge(config, dataCommon or {}, true)
		libTable:Merge(config, dataRealm or {}, true)
	end

	callback(config, nil)
end

function LIB:LoadConfigs(filenames, callback)
	assert(isfunction(callback) or istable(callback), "bad argument #2, expected a callable")

	if not istable(filenames) or libClass:isa(filenames, "file/path") then
		filenames = {filenames}
	end

	if SERVER then
		self:LoadConfigFiles(filenames, false, callback)
		return
	end

	local receiver = libNet:CreateReceiver("load_config")
	receiver:Remove()

	receiver = libNet:CreateReceiver("load_config")
	receiver.OnError = function(this, status, statusname)
		callback(nil, string.format("Config transmission error %d ('%s')", status, statusname))
	end

	receiver.OnTimeout = function(this)
		callback(nil, "Config transmission timeout")
	end

	receiver.OnCancel = function(this)
		callback(nil, "Config transmission canceled")
	end

	receiver.OnReceive = function(this, stream)
		local err = stream:ReadString()

		if err ~= "" then
			callback(nil, err)
			return
		end

		local config = stream:ReadJson()
		if not config then
			callback(nil, "Config transmission data error")
			return
		end

		callback(config, nil)
	end

	receiver.OnDone = function(this)
		this:Remove()
	end

	local streamToSend = libClass:CreateObj("stream")
	streamToSend:WriteUInt16(#filenames)

	for i, filename in ipairs(filenames) do
		if istable(filename) and libClass:isa(filename, "file/path") then
			filename = filename:GetVirtualString()
		end

		streamToSend:WriteString(filename)
	end

	local sender = libNet:CreateSender("load_config")
	sender:Send(ply, streamToSend)

	sender.OnError = function(this, status, statusname)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(nil, string.format("Config transmission error %d ('%s')", status, statusname))
	end

	sender.OnTimeout = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(nil, "Config transmission timeout")
	end

	sender.OnCancel = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(nil, "Config transmission canceled")
	end
end


return LIB
