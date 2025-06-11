local libNet = nil
local libFile = nil
local libHash = nil
local libPrint = nil
local libTable = nil
local libClass = nil

local LIB = {}
LIB._whitelist = {}
LIB._callbacks = {}


LIB.STATUS_OK = 0
LIB.STATUS_OK_SAME_HASH = 1
LIB.STATUS_NOT_FOUND = 2
LIB.STATUS_NOT_READABLE = 3
LIB.STATUS_ILLEGAL_FILENAME = 2

LIB.ERRORTEXTS = {
	[LIB.STATUS_NOT_FOUND] = "The file was not found.",
	[LIB.STATUS_NOT_READABLE] = "The file is not readable.",
	[LIB.STATUS_ILLEGAL_FILENAME] = "The file is not allowed to be downloaded.",
}

local function getDownloadChannelName(filenames)
	namespace = tostring(namespace or "")
	filename = tostring(filename or "")

	local h = {}

	for i, filename in ipairs(filenames) do
		filename = libFile:ResolvePath(filename, "SELFDATA")
		filename = filename:GetVirtualString()

		h[#h + 1] = filename
	end

	table.sort(h)
	h = libTable:Hash(h)

	local channalname = string.format("download_%s", h)
	return channalname
end


function LIB:Load(lib)
	libNet = lib.net
	libFile = lib.file
	libHash = lib.hash
	libPrint = lib.print
	libTable = lib.table
	libDebug = lib.debug
end

function LIB:Ready(lib)
	libClass = lib.class
	local class = libClass:GetClass("stream")

	class:AddWriter("DownloadFileRequest", function(this, value)
		local filename = value.filename or ""
		local hash = value.hash or ""

		filename = libFile:ResolvePath(filename, "SELFDATA")
		filename = filename:GetVirtualString()

		this:WriteString(filename)
		this:WriteString(hash)
	end, true)

	class:AddReader("DownloadFileRequest", function(this)
		local filename = this:ReadString()
		local hash = this:ReadString()

		filename = libFile:ResolvePath(filename, "SELFDATA")

		local value = {
			filename = filename,
			hash = hash,
		}

		return value
	end, true)

	class:AddWriter("DownloadFileResponse", function(this, value)
		local filename = value.filename or ""
		local status = value.status or ""
		local data = value.data or ""

		filename = libFile:ResolvePath(filename, "SELFDATA")
		filename = filename:GetVirtualString()

		this:WriteString(filename)
		this:WriteUInt8(status)

		if status ~= self.STATUS_OK then
			return
		end

		this:WriteString(util.Compress(data))
	end, true)

	class:AddReader("DownloadFileResponse", function(this)
		local filename = this:ReadString()
		local status = this:ReadUInt8()
		local data = nil

		filename = libFile:ResolvePath(filename, "SELFDATA")

		if status == self.STATUS_OK then
			data = util.Decompress(this:ReadString())
		end

		local value = {
			filename = filename,
			status = status,
			data = data,
		}

		return value
	end, true)

	self:DeleteDownloadCache()

	self:CreateDownloadReceiver()
	self:CreateDownloadWhitelistReceiver()
end

function LIB:Unload(lib)
	self:DeleteDownloadCache()
end

function LIB:GetErrorTextFromCode(errorcode)
	return self.ERRORTEXTS[errorcode] or "Unknown error"
end


function LIB:SetWhitelist(namespace, filenames)
	namespace = tostring(namespace or "")

	self._whitelist = self._whitelist or {}
	self._whitelist[namespace] = {}

	if not istable(filenames) or libClass:isa(filenames, "file/path") then
		filenames = {filenames}
	end

	for i, filename in ipairs(filenames) do
		self:AddToWhitelist(namespace, filename)
	end
end

function LIB:AddToWhitelist(namespace, filename)
	namespace = tostring(namespace or "")
	filename = libFile:ResolvePath(filename, "SELFDATA")
	filename = filename:GetVirtualString()

	self._whitelist = self._whitelist or {}
	self._whitelist[namespace] = self._whitelist[namespace] or {}
	self._whitelist[namespace][filename] = true
end

function LIB:RemoveFromWhitelist(namespace, filename)
	namespace = tostring(namespace or "")
	filename = libFile:ResolvePath(filename, "SELFDATA")
	filename = filename:GetVirtualString()

	self._whitelist = self._whitelist or {}
	self._whitelist[namespace] = self._whitelist[namespace] or {}
	self._whitelist[namespace][filename] = nil
end

function LIB:GetWhitelist(namespace)
	namespace = tostring(namespace or "")

	if not self._whitelist then
		return nil
	end

	if not self._whitelist[namespace] then
		return nil
	end

	return self._whitelist[namespace]
end

function LIB:IsAllowed(namespace, filename)
	namespace = tostring(namespace or "")
	filename = libFile:ResolvePath(filename, "SELFDATA")
	filename = filename:GetVirtualString()

	if not self._whitelist then
		return false
	end

	if not self._whitelist[namespace] then
		return false
	end

	if not self._whitelist[namespace][filename] then
		return false
	end

	return true
end

function LIB:CreateDownloadWhitelistReceiver()
	if not SERVER then
		return
	end

	local receiver = libNet:CreateReceiver("download_whitelist")

	receiver.OnReceive = function(this, stream, ply)
		local namespace = stream:ReadString()
		local hash = stream:ReadString()

		local streamToSend = libClass:CreateObj("stream")
		local whitelist = self:GetWhitelist(namespace) or {}
		local sender = libNet:CreateSender("download_whitelist")

		if hash ~= "" then
			local whitelistHash = libTable:Hash(whitelist)

			if whitelistHash == hash then
				streamToSend:WriteUInt8(self.STATUS_OK_SAME_HASH)

				sender:Send(ply, streamToSend)
				return
			end
		end

		whitelist = table.GetKeys(whitelist)
		table.sort(whitelist)

		streamToSend:WriteInt8(self.STATUS_OK)
		streamToSend:WriteStringTable(whitelist)

		sender:Send(ply, streamToSend)
	end

	receiver.OnRemove = function(this)
		self:CreateDownloadWhitelistReceiver()
	end

	return receiver
end

function LIB:CreateDownloadReceiver()
	if not SERVER then
		return
	end

	local receiver = libNet:CreateReceiver("download")

	local function printError(ply, namespace, filename, msg)
		ply = tostring(ply)
		namespace = tostring(namespace or "")
		msg = tostring(msg or "")

		filename = libFile:ResolvePath(filename, "SELFDATA")

		if namespace == "" then
			namespace = "<unknown namespace>"
		end

		if filename == "" then
			filename = "<unknown file>"
		end

		if msg == "" then
			msg = "Unknown error"
		end

		local err = string.format(
			"Download error @[Player: '%s']: %s\n  Namespace: '%s'\n  File: %s\n",
			ply,
			msg,
			namespace,
			filename
		)

		err = libDebug:Traceback(err)
		libPrint:printf(err .. "\n")
	end

	receiver.OnReceive = function(this, stream, ply)
		local namespace = stream:ReadString()
		local downloadFileRequests = stream:ReadDownloadFileRequestTable()

		local files = {}
		local downloadFileResponses = {}

		for i, downloadFileRequest in ipairs(downloadFileRequests) do
			local filename = downloadFileRequest.filename
			local hash = downloadFileRequest.hash

			files[#files + 1] = filename

			local downloadFileResponse = {}
			downloadFileResponses[#downloadFileResponses + 1] = downloadFileResponse

			downloadFileResponse.filename = filename

			if not self:IsAllowed(namespace, filename) then
				downloadFileResponse.status = self.STATUS_ILLEGAL_FILENAME
				printError(ply, namespace, filename, self:GetErrorTextFromCode(self.STATUS_ILLEGAL_FILENAME))
				continue
			end

			if not libFile:Exists(path) then
				downloadFileResponse.status = self.STATUS_NOT_FOUND
				printError(ply, namespace, filename, self:GetErrorTextFromCode(self.STATUS_NOT_FOUND))
				continue
			end

			local filedata = libFile:Read(filename)

			if not filedata then
				downloadFileResponse.status = self.STATUS_NOT_READABLE
				printError(ply, namespace, filename, self:GetErrorTextFromCode(self.STATUS_NOT_READABLE))
				continue
			end

			if hash ~= "" then
				local filehash = libHash:SHA256_SUM(filedata)

				if filehash == hash then
					downloadFileResponse.status = self.STATUS_OK_SAME_HASH
					continue
				end
			end

			downloadFileResponse.status = self.STATUS_OK
			downloadFileResponse.data = filedata
		end

		local streamToSend = libClass:CreateObj("stream")
		local sender = libNet:CreateSender(getDownloadChannelName(files))

		streamToSend:WriteDownloadFileResponseTable(downloadFileResponses)

		sender:Send(ply, streamToSend)
	end

	receiver.OnRemove = function(this)
		self:CreateDownloadReceiver()
	end

	return receiver
end

function LIB:GetCacheFilepath(filename)
	filename = libFile:ResolvePath(filename, "SELFDATA")
	local vmount = filename:GetVirtualMount()

	if vmount == "CACHE" then
		return filename
	end

	filename = filename:GetRealString()

	local hash = libHash:SHA256_SUM(filename)

	local cacheFilename = string.format("CACHE:download/%s.dat", hash)
	cacheFilename = libFile:ResolvePath(cacheFilename, "CACHE")

	return cacheFilename
end

function LIB:DeleteDownloadCache()
	if SERVER then
		return
	end

	return libFile:Delete("CACHE:download/")
end

function LIB:DeleteUnusedDownloadFiles(namespaces)
	if SERVER then
		return
	end

	if not istable(namespaces) then
		namespaces = {namespaces}
	end

	local whitelist = {}

	for i, namespace in ipairs(namespaces) do
		local wl = self:GetWhitelist(namespace)

		for i, filename in ipairs(wl) do
			local cacheFilename = self:GetCacheFilepath(filename)
			local cacheFilenameTemp = string.format("CACHE:tmp/%s.dat", cacheFilename:GetVirtualPath())
			cacheFilenameTemp = libFile:ResolvePath(cacheFilename, "CACHE")

			whitelist[#whitelist + 1] = {cacheFilename, cacheFilenameTemp}

			libFile:Rename(cacheFilename, cacheFilenameTemp)
		end
	end

	self:DeleteDownloadCache()

	for i, v in ipairs(whitelist) do
		local cacheFilename, cacheFilenameTemp = unpack(v)
		libFile:Rename(cacheFilenameTemp, cacheFilename)
	end

	libFile:Delete("CACHE:tmp/download/")
end

function LIB:DownloadFileBundle(namespace, filenames, callback, progressCallback)
	if SERVER then
		return
	end

	assert(isfunction(callback) or istable(callback), "bad argument #3, expected a callable")

	if progressCallback then
		assert(isfunction(progressCallback) or istable(progressCallback), "bad argument #4, expected a callable")
	end

	namespace = tostring(namespace or "")

	if not istable(filenames) or libClass:isa(filenames, "file/path") then
		filenames = {filenames}
	end

	local downloadFileRequests = {}
	local files = {}

	for i, filename in ipairs(filenames) do
		local cacheFilename = self:GetCacheFilepath(filename)
		local cacheFiledata = libFile:Read(cacheFilename)
		local cacheFilehash = ""

		if cacheFiledata then
			cacheFilehash = libHash:SHA256_SUM(cacheFiledata)
		end

		local downloadFileRequest = {
			filename = filename,
			hash = cacheFilehash,
		}

		files[#files + 1] = filename
		downloadFileRequests[#downloadFileRequests + 1] = downloadFileRequest
	end

	local channalname = getDownloadChannelName(files)
	local receiver = libNet:CreateReceiver(channalname)
	receiver:Remove()

	receiver = libNet:CreateReceiver(channalname)
	receiver.OnProgress = function(this, data)
		if not progressCallback then
			return true
		end

		if progressCallback(data) == false then
			return false
		end

		return true
	end

	receiver.OnError = function(this, status, statusname)
		callback(false, nil, string.format("File transmission error %d ('%s')", status, statusname))
	end

	receiver.OnTimeout = function(this)
		callback(false, nil, "File transmission timeout")
	end

	receiver.OnCancel = function(this)
		callback(false, nil, "File transmission canceled")
	end

	receiver.OnReceive = function(this, stream)
		local downloadFileResponses = stream:ReadDownloadFileResponseTable()
		local returndata = {}

		local success = true

		for i, downloadFileResponse in ipairs(downloadFileResponses) do
			local filename = downloadFileResponse.filename
			local status = downloadFileResponse.status
			local data = downloadFileResponse.data

			local downloadFilename = self:GetCacheFilepath(filename)

			if status == self.STATUS_OK_SAME_HASH then
				if not libFile:Exists(downloadFilename) then
					returndata[#returndata + 1] = {
						filename = filename,
						downloadFilename = nil,
						error = string.format("File transmission cache error: Does not exist '%s'", downloadFilename),
						errorCode = nil,
					}

					success = false
					continue
				end

				returndata[#returndata + 1] = {
					filename = filename,
					downloadFilename = downloadFilename,
					error = nil,
					errorCode = nil,
				}

				continue
			end

			if status == self.STATUS_OK then
				if not data then
					returndata[#returndata + 1] = {
						filename = filename,
						downloadFilename = nil,
						error = "File transmission data error",
						errorCode = nil,
					}

					success = false
					continue
				end

				if not libFile:Write(downloadFilename, data) then
					returndata[#returndata + 1] = {
						filename = filename,
						downloadFilename = nil,
						error = string.format("File transmission cache error: Could not write to file '%s'", downloadFilename),
						errorCode = nil,
					}

					success = false
					continue
				end

				returndata[#returndata + 1] = {
					filename = filename,
					downloadFilename = downloadFilename,
					error = nil,
					errorCode = nil,
				}

				continue
			end

			returndata[#returndata + 1] = {
				filename = filename,
				downloadFilename = nil,
				error = string.format("File transmission data error: %s", self:GetErrorTextFromCode(status)),
				errorCode = status,
			}

			success = false
		end

		callback(success, returndata, nil)
	end

	receiver.OnDone = function(this)
		this:Remove()
	end

	local streamToSend = libClass:CreateObj("stream")

	streamToSend:WriteString(namespace)
	streamToSend:WriteDownloadFileRequestTable(downloadFileRequests)

	local sender = libNet:CreateSender("download")
	sender:Send(ply, streamToSend)

	sender.OnError = function(this, status, statusname)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(false, nil, string.format("File transmission error %d ('%s')", status, statusname))
	end

	sender.OnTimeout = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(false, nil, "File transmission timeout")
	end

	sender.OnCancel = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(false, nil, "File transmission canceled")
	end
end

function LIB:DownloadFileBundles(namespace, filenameBundles, callbackDone, callbackBundleDone, progressCallback)
	if SERVER then
		return
	end

	assert(isfunction(callbackDone) or istable(callbackDone), "bad argument #3, expected a callable")

	if callbackBundleDone then
		assert(isfunction(callbackBundleDone) or istable(callbackBundleDone), "bad argument #4, expected a callable")
	end

	if progressCallback then
		assert(isfunction(progressCallback) or istable(progressCallback), "bad argument #5, expected a callable")
	end

	local queue = libClass:CreateObj("queue")

	for i, filenames in ipairs(filenameBundles) do
		if not istable(filenames) or libClass:isa(filenames, "file/path") then
			filenames = {filenames}
		end

		if #filenames <= 0 then
			continue
		end

		queue:PushLeft(filenames)
	end

	local errors = {}
	local hasErrors = false

	local downloadNextFile = nil
	local count = queue:GetSize()
	local index = 0

	downloadNextFileBundle = function()
		local filenames = queue:PopRight()
		index = index + 1

		if not filenames then
			if not hasErrors then
				errors = nil
			end

			callbackDone(not hasErrors, errors)
			return
		end

		self:DownloadFileBundle(namespace, filenames, function(success, data, err, ...)
			local thisErrors = {}

			if err then
				for i, filename in ipairs(filenames) do
					filename = libFile:ResolvePath(filename, "SELFDATA")
					filename = filename:GetVirtualString()

					errors[filename] = err
					thisErrors[filename] = err
					hasErrors = true
				end
			end

			if data then
				for i, v in ipairs(data) do
					if not v.error then
						continue
					end

					local filename = v.filename
					filename = libFile:ResolvePath(filename, "SELFDATA")
					filename = filename:GetVirtualString()

					errors[filename] = v.error
					thisErrors[filename] = v.error
					hasErrors = true
				end
			end

			callbackBundleDone(success, data, thisErrors, index, count, ...)
			downloadNextFileBundle()
		end, function(...)
			progressCallback(filenames, index, count, ...)
		end)
	end

	downloadNextFileBundle()
end

function LIB:DownloadWhitelist(namespace, callback, progressCallback)
	if SERVER then
		return
	end

	assert(isfunction(callback) or istable(callback), "bad argument #2, expected a callable")

	if progressCallback then
		assert(isfunction(progressCallback) or istable(progressCallback), "bad argument #3, expected a callable")
	end

	namespace = tostring(namespace or "")

	local whitelist = self:GetWhitelist(namespace) or {}
	local whitelistHash = libTable:Hash(whitelist)

	if not table.IsEmpty(whitelist) then
		whitelistHash = libTable:Hash(whitelist)
	end

	whitelist = table.GetKeys(whitelist)
	table.sort(whitelist)

	local channalname = "download_whitelist"
	local receiver = libNet:CreateReceiver(channalname)
	receiver:Remove()

	receiver = libNet:CreateReceiver(channalname)
	receiver.OnProgress = function(this, data)
		if not progressCallback then
			return true
		end

		if progressCallback(data) == false then
			return false
		end

		return true
	end

	receiver.OnError = function(this, status, statusname)
		callback(nil, string.format("File whitelist transmission error %d ('%s')", status, statusname))
	end

	receiver.OnTimeout = function(this)
		callback(nil, "File whitelist transmission timeout")
	end

	receiver.OnCancel = function(this)
		callback(nil, "File whitelist transmission canceled")
	end

	receiver.OnReceive = function(this, stream)
		local errorCode = stream:ReadUInt8()

		if errorCode == self.STATUS_OK_SAME_HASH then
			callback(whitelist, nil)
			return
		end

		if errorCode == self.STATUS_OK then
			local whitelist = stream:ReadStringTable()

			if not whitelist then
				callback(nil, "File whitelist transmission data error")
				return
			end

			self:SetWhitelist(namespace, whitelist)

			callback(whitelist, nil)
			return
		end

		callback(nil, string.format("File whitelist transmission data error: %s", self:GetErrorTextFromCode(errorCode)), errorCode)
	end

	receiver.OnDone = function(this)
		this:Remove()
	end

	local streamToSend = libClass:CreateObj("stream")
	streamToSend:WriteString(namespace)
	streamToSend:WriteString(whitelistHash)

	local sender = libNet:CreateSender("download_whitelist")
	sender:Send(ply, streamToSend)

	sender.OnError = function(this, status, statusname)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(nil, string.format("File whitelist transmission error %d ('%s')", status, statusname))
	end

	sender.OnTimeout = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(nil, "File whitelist transmission timeout")
	end

	sender.OnCancel = function(this)
		receiver.OnError = nil
		receiver.OnTimeout = nil
		receiver.OnCancel = nil
		receiver.OnReceive = nil
		receiver:Remove()

		callback(nil, "File whitelist transmission canceled")
	end
end

function LIB:DownloadWhitelistedFiles(namespace, chunkSize, callbackDone, callbackBundleDone, progressCallback)
	if SERVER then
		return
	end

	assert(isfunction(callbackDone) or istable(callbackDone), "bad argument #2, expected a callable")

	if callbackBundleDone then
		assert(isfunction(callbackBundleDone) or istable(callbackBundleDone), "bad argument #3, expected a callable")
	end

	if progressCallback then
		assert(isfunction(progressCallback) or istable(progressCallback), "bad argument #4, expected a callable")
	end

	self:DownloadWhitelist(namespace, function(filenames, err, ...)
		local success = not err
		err = {err}

		callbackBundleDone(success, filenames, err, nil, nil, ...)
		if not success then
			callbackDone(false, err)
			return
		end

		local filenameBundles = libTable:Split(filenames, chunkSize)
		self:DownloadFileBundles(namespace, filenameBundles, callbackDone, callbackBundleDone, progressCallback)
	end, function(...)
		progressCallback(nil, nil, nil, ...)
	end)
end


return LIB
