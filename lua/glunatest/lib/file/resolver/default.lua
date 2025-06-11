local RESOLVER = {}

RESOLVER.priority = math.huge

local g_mountmap = {
	[""] = "DATA",
	["GAME"] = "GAME",
	["LUA"] = "LUA",
	["LSV"] = "lsv",
	["LCL"] = "lcl",
	["DATA"] = "DATA",
	["MOD"] = "MOD",
	["DOWNLOAD"] = "DOWNLOAD",
	["THIRDPARTY"] = "THIRDPARTY",
	["WORKSHOP"] = "WORKSHOP",
}

function RESOLVER:Resolve(Filelib, mount, path)
	mount = g_mountmap[string.upper(mount)]

	if mount then
		return path, mount
	end

	return nil
end

return RESOLVER
