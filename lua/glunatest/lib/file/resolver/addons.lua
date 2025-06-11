local libFile = nil
local libJson = nil

local RESOLVER = {}

RESOLVER.priority = 10000
RESOLVER._addoncache = nil
RESOLVER._addonfindcache = {}

function RESOLVER:GetAddons()
	if self._addoncache then
		return self._addoncache
	end

	local _, directories = file.Find("addons/*", "GAME");

	local addons = {}

	for i, v in ipairs(directories) do
		local name = v
		local path = libFile:SanitizeFilename("addons/" .. name)
		local isdir = file.IsDir(path, "GAME")

		if not isdir then
			continue
		end

		local jsonfile = libFile:SanitizeFilename(path .. "/addon.json")
		local addonmeta = {}

		if file.Exists(jsonfile, "GAME") then
			addonmeta = libJson:Decode(file.Read(jsonfile, "GAME"))
		end

		local title = string.Trim(tostring(addonmeta.title or ""))

		if title == "" then
			title = nil
		end

		local description = string.Trim(tostring(addonmeta.description or ""))

		if description == "" then
			description = nil
		end

		addons[#addons + 1] = {
			path = path,
			mount = "GAME",
			name = name,
			title = title,
			description = description,
		}
	end

	self._addoncache = addons
	return self._addoncache
end

function RESOLVER:Resolve(Filelib, mount, path)
	libFile = Filelib
	libJson = libFile.LIB.json

	if self._addonfindcache[mount] then
		return unpack(self._addonfindcache[mount])
	end

	self._addonfindcache[mount] = nil

	local addon = string.match(mount, "^ADDON%[[%s]*%'(.+)%'[%s]*%]")

	if not addon then
		addon = string.match(mount, '^ADDON%[[%s]*%"(.+)%"[%s]*%]')
	end

	if not addon then
		addon = string.match(mount, "^ADDON%[[%s]*(.+)[%s]*%]")
	end

	addon = string.Trim(tostring(addon or ""))

	if addon == "" then
		return nil
	end

	local addons = self:GetAddons()

	local checkfor = {
		"name",
		"titel",
		"id",
	}

	local lowercase = false

	for case=1, 2 do
		local aname = addon

		if lowercase then
			aname = string.lower(aname)
		end

		for _, checkvar in ipairs(checkfor) do
			for _, thisaddon in ipairs(addons) do
				local var = string.Trim(tostring(thisaddon[checkvar] or ""))

				if var == "" then
					continue
				end

				local addonpath = thisaddon.path
				local addonmount = thisaddon.mount

				if not addonpath then
					continue
				end

				if not addonmount then
					continue
				end

				addonpath = addonpath .. "/" .. path

				if lowercase then
					var = string.lower(var)
				end

				if var == aname then
					self._addonfindcache[mount] = {addonpath, addonmount}
					return addonpath, addonmount
				end
			end
		end

		lowercase = not lowercase
	end

	return nil
end

return RESOLVER
