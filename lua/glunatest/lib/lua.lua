local libFile = nil
local libHash = nil
local libPrint = nil
local libDownload = nil
local libClass = nil

local LIB = {}
LIB.DEFAULT_DOWNLOAD_NAMESPACE = "cl_lua"

function LIB:Load(lib)
	libFile = lib.file
	libHash = lib.hash
	libPrint = lib.print
	libDownload = lib.download
	libClass = lib.class
end

function LIB:ResolvePath(path)
	path = libFile:ResolvePath(path, "LUA")
	return path
end

function LIB:RunCode(code, name, ...)
	local func = self:CompileCode(code, name)
	return func(name, ...)
end

function LIB:RunFile(path, ...)
	local func = self:CompileFile(path)
	return func(name, ...)
end

function LIB:RunDownloadFile(path, ...)
	if SERVER then
		return
	end

	local func = self:CompileDownloadFile(path)
	return func(name, ...)
end

function LIB:CompileCode(code, name)
	name = tostring(name or "")
	code = tostring(code or "")

	if name == "" then
		name = libHash:MD5_SUM(code)
		name = string.upper(name)
		name = "Unnamed Code: " .. name
	end

	local func = CompileString(code, name, false)
	if not isfunction(func) then
		func = tostring(func or "")

		if func == "" then
			libPrint:errorf("Couldn't compile code '%s' (Syntax error)\n", 0, name)
		end

		libPrint:error(func, 0)
	end

	return func
end

function LIB:CompileFile(path)
	path = self:ResolvePath(path)
	local name = path:GetRealString()

	if not libFile:Exists(path) then
		libPrint:errorf("Couldn't compile file '%s' (File not found)\n", 0, name)
	end

	local code = libFile:Read(path)

	if not code then
		libPrint:errorf("Couldn't compile file '%s' (File not readable)\n", 0, name)
	end

	return self:CompileCode(code, name)
end

function LIB:CompileDownloadFile(path)
	if SERVER then
		return
	end

	path = self:ResolvePath(path)

	local cachePath = libDownload:GetCacheFilepath(path)
	local name = string.format("%s | %s", path:GetRealString(), cachePath:GetRealString())

	if not libFile:Exists(cachePath) then
		libPrint:errorf("Couldn't compile cache file '%s' (File not found)\n", 0, name)
	end

	local code = libFile:Read(cachePath)

	if not code then
		libPrint:errorf("Couldn't compile cache file '%s' (File not readable)\n", 0, name)
	end

	return self:CompileCode(code, name)
end

function LIB:Exists(path)
	path = self:ResolvePath(path)

	if CLIENT then
		local cachePath = libDownload:GetCacheFilepath(path)
		if libFile:Exists(cachePath) then
			return true
		end
	end

	if libFile:Exists(path) then
		return true
	end

	return false
end

function LIB:Read(path)
	path = self:ResolvePath(path)

	if CLIENT then
		local cachePath = libDownload:GetCacheFilepath(path)
		if libFile:Exists(cachePath) then
			return libFile:Read(cachePath)
		end
	end

	if libFile:Exists(path) then
		return libFile:Read(path)
	end

	return nil
end

function LIB:AddCSLuaFile(path)
	if not SERVER then
		return
	end

	path = self:ResolvePath(path)
	path = path:GetReal()

	local ext = string.lower(string.GetExtensionFromFilename(path))
	if ext ~= "lua" then
		return
	end

	AddCSLuaFile(path)
end

function LIB:AddCSLuaFiles(paths)
	if not SERVER then
		return
	end

	if not istable(paths) or libClass:isa(paths, "file/path") then
		paths = {paths}
	end

	for k, v in pairs(paths) do
		self:AddCSLuaFile(v)
	end
end

function LIB:AddCSLuaFolder(path)
	if not SERVER then
		return
	end

	path = self:ResolvePath(path)
	if not libFile:IsDir(path) then
		return
	end

	local files, folders = libFile:Find(path, "/*")

	for k, v in pairs(files) do
		local filepath = libFile:Concat(path, "/", v)

		if not filepath then
			continue
		end

		self:AddCSLuaFile(filepath)
	end

	for k, v in pairs(folders) do
		local folderpath = libFile:Concat(path, "/", v)

		if not folderpath then
			continue
		end

		self:AddCSLuaFolders(folderpath)
	end
end

function LIB:AddCSLuaFolders(paths)
	if not SERVER then
		return
	end

	if not istable(paths) or libClass:isa(paths, "file/path") then
		paths = {paths}
	end

	for k, v in pairs(paths) do
		self:AddCSLuaFolder(v)
	end
end

function LIB:AddCSDownloadLuaFile(path, namespace)
	if not SERVER then
		return
	end

	namespace = tostring(namespace or "")

	if namespace == "" then
		namespace = self.DEFAULT_DOWNLOAD_NAMESPACE
	end

	path = self:ResolvePath(path)

	local ext = string.lower(string.GetExtensionFromFilename(path:GetReal()))
	if ext ~= "lua" then
		return
	end

	libDownload:AddToWhitelist(namespace, path)
end

function LIB:AddCSDownloadLuaFiles(paths, namespace)
	if not SERVER then
		return
	end

	namespace = tostring(namespace or "")

	if namespace == "" then
		namespace = self.DEFAULT_DOWNLOAD_NAMESPACE
	end

	if not istable(paths) or libClass:isa(paths, "file/path") then
		paths = {paths}
	end

	for k, v in pairs(paths) do
		self:AddCSDownloadLuaFile(v, namespace)
	end
end

function LIB:AddCSDownloadLuaFolder(path, namespace)
	if not SERVER then
		return
	end

	namespace = tostring(namespace or "")

	if namespace == "" then
		namespace = self.DEFAULT_DOWNLOAD_NAMESPACE
	end

	path = self:ResolvePath(path)
	if not libFile:IsDir(path) then
		return
	end

	local files, folders = libFile:Find(path, "/*")

	for k, v in pairs(files) do
		local filepath = libFile:Concat(path, "/", v)

		if not filepath then
			continue
		end

		self:AddCSDownloadLuaFile(filepath, namespace)
	end

	for k, v in pairs(folders) do
		local folderpath = libFile:Concat(path, "/", v)

		if not folderpath then
			continue
		end

		self:AddCSDownloadLuaFolder(folderpath, namespace)
	end
end

function LIB:AddCSDownloadLuaFolders(paths, namespace)
	if not SERVER then
		return
	end

	namespace = tostring(namespace or "")

	if namespace == "" then
		namespace = self.DEFAULT_DOWNLOAD_NAMESPACE
	end

	if not istable(paths) or libClass:isa(paths, "file/path") then
		paths = {paths}
	end

	for k, v in pairs(paths) do
		self:AddCSDownloadLuaFolder(v, namespace)
	end
end

function LIB:DownloadCSDownloadLuaFiles(namespace, callbackDone, callbackFileDone, progressCallback)
	if SERVER then
		return
	end

	namespace = tostring(namespace or "")

	if namespace == "" then
		namespace = self.DEFAULT_DOWNLOAD_NAMESPACE
	end

	libDownload:DownloadWhitelistedFiles(namespace, 10, callbackDone, callbackFileDone, progressCallback)
end

return LIB
