local libLib = nil
local libString = nil
local libTable = nil
local libJson = nil

local LIB = {}

LIB._resolvers = {}
LIB._resolveCache = {}

function LIB:Load(lib)
	libLib = lib
	libString = lib.string
	libTable = lib.table
	libJson = lib.json

	local basepath = "lib/file/resolver"
	local files = file.Find(libLib.LUAPATH .. "/" ..  basepath .. "/*.lua", "LUA");

	for i, v in ipairs(files) do
		local path = self:SanitizeFilename(basepath .. "/" .. v)

		local resolver = libLib:Load(path)
		if not resolver then
			continue
		end

		self:AddResolver(resolver)
	end
end

function LIB:AddResolver(callable)
	if not callable then
		return
	end

	self._resolvers[#self._resolvers + 1] = callable
end

function LIB:GetResolvers()
	return self._resolvers
end

local function parsePathData(path)
	local pathData = {}

	if isfunction(path) then
		local vpath, vmount = path()

		pathData[#pathData + 1] = vmount
		pathData[#pathData + 1] = vpath
	else
		if not istable(path) then
			path = tostring(path or "")
			path = string.Explode(":", path, false) or {}
		end

		if isfunction(path.GetVirtual) then
			local vpath, vmount = path:GetVirtual()

			pathData[#pathData + 1] = vmount
			pathData[#pathData + 1] = vpath
		else
			pathData[#pathData + 1] = path[1] or path.mount or path.context
			pathData[#pathData + 1] = path[2] or path.path or path.file or path.folder
		end
	end

	local len = #pathData

	if len <= 0 then
		return nil
	end

	if len == 1 then
		return {"", string.Trim(tostring(pathData[1] or ""))}
	end

	if len == 2 then
		local mount = string.Trim(tostring(pathData[1] or ""))
		return {mount, string.Trim(tostring(pathData[2] or ""))}
	end

	return nil
end

function LIB:ResolvePath(path, defaultmount)
	local pathData = parsePathData(path)

	if not pathData then
		return nil
	end

	local thismount = pathData[1]
	local thispath = pathData[2]

	defaultmount = tostring(defaultmount or "")

	if defaultmount == "" then
		defaultmount = "DATA"
	end

	thismount = tostring(thismount or "")
	thispath = self:SanitizeFilename(thispath)

	if thismount == "" then
		thismount = defaultmount
	end

	local cachekey = string.format("%s:%s", thismount, thispath)

	if self._resolveCache[cachekey] then
		return self._resolveCache[cachekey]
	end

	self._resolveCache[cachekey] = nil

	local pathObj = libLib.class:CreateObj("file/path", thismount, thispath, defaultmount)

	if not IsValid(pathObj) then
		return nil
	end

	self._resolveCache[cachekey] = pathObj
	self._resolveCache[pathObj:GetVirtualString()] = pathObj

	return pathObj
end

function LIB:Concat(pathObj, ...)
	local str = self:SanitizeFilename(table.concat({...}))

	local pathData = parsePathData(pathObj)
	pathData[2] = pathData[2] .. str

	return self:ResolvePath(pathData)
end

function LIB:ResolvePathSimple(...)
	local pathObj = self:ResolvePath(...)

	if not pathObj then
		return nil, nil
	end

	return pathObj:GetReal()
end

function LIB:SanitizeFilename(text)
	text = libString:NormalizeSlashes(text)
	text = string.Trim(text)
	text = string.lower(text)

	text = string.gsub(text, "%s+" , "_")
	text = string.gsub(text, "%c+" , "")
	text = string.gsub(text, "[^%w_%-%.%/]" , "-")
	text = string.gsub(text, "%.%.%/" , "")
	text = string.gsub(text, "%/%.%/" , "/")
	text = string.gsub(text, "^%.%/" , "")
	text = libString:NormalizeSlashes(text)

	return text
end

function LIB:SanitizePathData(pathData)
	pathData = parsePathData(pathData)
	pathData[2] = self:SanitizeFilename(pathData[2])
	pathData = self:ResolvePath(pathData)

	return pathData
end

function LIB:GetPathFromFilename(pathData)
	pathData = parsePathData(pathData)
	pathData[2] = string.GetPathFromFilename(pathData[2])
	pathData = self:ResolvePath(pathData)

	return pathData
end

function LIB:GetFileFromFilename(pathData)
	pathData = parsePathData(pathData)
	return string.GetFileFromFilename(pathData[2])
end

function LIB:GetExtensionFromFilename(pathData)
	pathData = parsePathData(pathData)
	return string.GetExtensionFromFilename(pathData[2])
end

function LIB:StripExtension(pathData)
	pathData = parsePathData(pathData)
	pathData[2] = string.StripExtension(pathData[2])
	pathData = self:ResolvePath(pathData)

	return pathData
end

function LIB:SetExtensionOfFilename(pathData, ext)
	ext = self:SanitizeFilename(ext)

	pathData = parsePathData(pathData)
	pathData[2] = string.StripExtension(pathData[2])

	if ext ~= "" then
		pathData[2] = string.format("%s.%s", pathData[2], ext)
	end

	pathData = self:ResolvePath(pathData)

	return pathData
end

function LIB:SetFileOfFilename(pathData, filename)
	filename = self:SanitizeFilename(filename)

	pathData = parsePathData(pathData)
	pathData[2] = string.GetPathFromFilename(pathData[2])

	if ext ~= "" then
		pathData[2] = string.format("%s/%s", pathData[2], filename)
	end

	pathData = self:ResolvePath(pathData)

	return pathData
end

local function createParentDirOfFile(path)
	path = string.GetPathFromFilename(path)
	local mount = "DATA"

	if not file.IsDir(path, mount) then
		file.CreateDir(path)
	end

	return file.IsDir(path, mount)
end

local function deleteRecursive(path)
	local delete = nil
	local mount = "DATA"

	delete = function(thispath)
		if file.IsDir(thispath, mount) then
			local files, folders = file.Find(thispath .. "/*", mount)

			local ok = true

			for i, v in ipairs(files or {}) do
				if not delete(thispath .. "/" .. v) then
					ok = false
				end
			end

			for i, v in ipairs(folders or {}) do
				if not delete(thispath .. "/" .. v) then
					ok = false
				end
			end

			if not ok then
				return false
			end
		end

		if file.Exists(thispath, mount) then
			file.Delete(thispath)
		end

		if file.IsDir(thispath, mount) then
			return false
		end

		if file.Exists(thispath, mount) then
			return false
		end

		return true
	end

	return delete(path)
end


function LIB:Append(virtualpath, contents)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local realpath, realmount = pathObj:GetReal()

	if realmount ~= "DATA" then
		return nil
	end

	if not createParentDirOfFile(realpath) then
		return nil
	end

	local f = self:Open(pathObj, "ab")
	if not f then
		return false
	end

	contents = tostring(contents or "")

	f:Write(contents)
	f:Close()

	return true
end

function LIB:CreateDir(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local realpath, realmount = pathObj:GetReal()

	if realmount ~= "DATA" then
		return nil
	end

	if not file.IsDir(realpath, realmount) then
		file.CreateDir(realpath)
	end

	return file.IsDir(realpath, realmount)
end

function LIB:Delete(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local realpath, realmount = pathObj:GetReal()

	if realmount ~= "DATA" then
		return nil
	end

	return deleteRecursive(realpath)
end

function LIB:Exists(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return false
	end

	local realpath, realmount = pathObj:GetReal()

	return file.Exists(realpath, realmount)
end

function LIB:Find(virtualpath, wildcard, sorting)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return {}, {}
	end

	local realpath, realmount = pathObj:GetReal()

	realpath = realpath .. tostring(wildcard or "")

	local files, folders = file.Find(realpath, realmount, sorting)

	files = files or {}
	folders = folders or {}

	return files, folders
end

function LIB:IsDir(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local realpath, realmount = pathObj:GetReal()

	return file.IsDir(realpath, realmount)
end

function LIB:Open(virtualpath, mode)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local realpath, realmount = pathObj:GetReal()

	return file.Open(realpath, mode, realmount)
end

function LIB:Read(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local realpath, realmount = pathObj:GetReal()

	return file.Read(realpath, realmount)
end

function LIB:Rename(virtualpathA, virtualpathB)
	local pathObjA = self:ResolvePath(virtualpath)

	if not pathObjA then
		return false
	end

	local realpathA, realmountA = pathObjA:GetReal()

	if realmountA ~= "DATA" then
		return false
	end

	local pathObjB = self:ResolvePath(virtualpath)

	if not pathObjB then
		return false
	end

	local realpathB, realmountB = pathObjB:GetReal()

	if realmountB ~= "DATA" then
		return false
	end

	if not createParentDirOfFile(realpathB) then
		return false
	end

	return file.Rename(realpathA, realpathB)
end

function LIB:Size(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return -1
	end

	local realpath, realmount = pathObj:GetReal()

	return file.Size(realpath, realmount)
end

function LIB:Time(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return -1
	end

	local realpath, realmount = pathObj:GetReal()

	return file.Time(realpath, realmount)
end

function LIB:Write(virtualpath, contents)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return false
	end

	local realpath, realmount = pathObj:GetReal()

	if realmount ~= "DATA" then
		return false
	end

	if not createParentDirOfFile(realpath) then
		return false
	end

	local f = self:Open(pathObj, "wb")
	if not f then
		return false
	end

	contents = tostring(contents or "")

	f:Write(contents)
	f:Close()

	return true
end

function LIB:Hash(virtualpath)
	local pathObj = self:ResolvePath(virtualpath)

	if not pathObj then
		return nil
	end

	local size = self:Size(pathObj)
	local time = self:Time(pathObj)

	if size == -1 then
		return nil
	end

	if time == -1 then
		return nil
	end

	local hash = {
		size,
		time,
		pathObj:GetRealString()
	}

	hash = libTable:Hash(hash)
	return hash
end


return LIB
