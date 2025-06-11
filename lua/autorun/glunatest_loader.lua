AddCSLuaFile()

local init = nil

init = function()
	local g_G = _G._GLunaTestLib_GetRootGlobal and _G._GLunaTestLib_GetRootGlobal() or _G
	local unload = nil

	unload = function()
		local err = nil
		local oldGLunaTestLib = (g_G.GetGLunaTestLib and g_G.GetGLunaTestLib()) or (_G.GetGLunaTestLib and _G.GetGLunaTestLib()) or g_G.GLunaTestLib or _G.GLunaTestLib

		xpcall(function()
			if not oldGLunaTestLib then
				return
			end

			oldGLunaTestLib:Unload()
			oldGLunaTestLib = nil

			MsgN("GLunaTestLib destroyed!")
		end, function(thisErr)
			err = tostring(thisErr or "")
		end)

		if err then
			if err == "" then
				err = "Unknown error!"
			end

			ErrorNoHalt(err .. "\n")
		end

		oldGLunaTestLib = nil
		g_G.GLunaTestLib = nil
		_G.GLunaTestLib = nil
	end

	unload()

	local lib = include("glunatest/lib.lua")

	g_G.GLunaTestLib = lib
	_G.GLunaTestLib = lib

	function g_G:GetGLunaTestLib()
		return lib
	end

	function g_G:_GLunaTestLib_GetRootGlobal()
		return g_G
	end

	_G._GLunaTestLib_GetRootGlobal = g_G._GLunaTestLib_GetRootGlobal
	_G.GetGLunaTestLib = g_G.GetGLunaTestLib

	lib:Init()

	local libConcommand = lib.concommand
	local libHook = lib.hook

	libConcommand:Add("reload", function(ply, args, cmd, cmdlong)
		init()
	end, libConcommand.SHARED, "Reloads the lua code of ##PROJECTNAME##.")

	libHook:Add("ShutDown", "shutdown", function()
		unload()
	end)

	if SERVER then
		MsgN("GLunaTestLib initialized! Enter sv_glunatest_help to get started!")
	else
		MsgN("GLunaTestLib initialized! Enter cl_glunatest_help to get started!")
	end
end

init()
