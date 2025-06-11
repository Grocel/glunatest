local RESOLVER = {}

RESOLVER.priority = 100000

function RESOLVER:Resolve(Filelib, mount, path)
	mount = string.upper(mount)

	local datapath = Filelib.LIB:GetDataPath()
	local datapathstatic = Filelib.LIB:GetStaticDataPath()
	local luapath = Filelib.LIB:GetLuaPath()

	local mountdata = "DATA"
	local mountlua = "LUA"
	local mountstatic = "GAME"

	if mount == "SELF" then
		return datapath .. "/" .. path, mountdata
	end

	if mount == "SELFDATA" then
		return datapath .. "/" .. path, mountdata
	end

	if mount == "CACHE" then
		return datapath .. "/cache/" .. path, mountdata
	end

	if mount == "CONFIG" then
		return datapath .. "/config/" .. path, mountdata
	end

	if mount == "CONFIG_CLIENT" then
		return datapath .. "/config/client/" .. path, mountdata
	end

	if mount == "CONFIG_SERVER" then
		return datapath .. "/config/server/" .. path, mountdata
	end

	if mount == "CONFIG_STATIC" then
		return datapathstatic .. "/config/" .. path, mountstatic
	end

	if mount == "CONFIG_CLIENT_STATIC" then
		return datapathstatic .. "/config/client/" .. path, mountstatic
	end

	if mount == "CONFIG_SERVER_STATIC" then
		return datapathstatic .. "/config/server/" .. path, mountstatic
	end

	if mount == "LOG" then
		return datapath .. "/log/" .. path, mountdata
	end

	if mount == "SELFLUA" then
		return luapath .. "/" .. path, mountlua
	end

	return nil
end

return RESOLVER
