local libString = nil
local libTable = nil
local libPrint = nil
local libColor = nil

local g_CMD = {}

local LIB = {}

LIB.SERVER = "SERVER"
LIB.CLIENT = "CLIENT"
LIB.SHARED = "SHARED"

function LIB:Load(lib)
	libString = lib.string
	libTable = lib.table
	libPrint = lib.print
	libColor = lib.color
end

function LIB:Add(relativeCmd, callback, realm, help, flags)
	relativeCmd = libString:SanitizeName(relativeCmd)

	realm = tostring(realm or "")
	realm = string.upper(realm)

	if realm == "" then
		realm = self.SHARED
	end

	help = tostring(help or "")
	help = string.Trim(help)
	help = libString:NormalizeNewlines(help)

	if help == "" then
		help = nil
	end

	flags = tonumber(flags or FCVAR_NONE) or FCVAR_NONE

	local isServer = (realm == self.SHARED) or (realm == self.SERVER)
	local isClient = (realm == self.SHARED) or (realm == self.CLIENT)

	local projecttitle = self.LIB:GetTitle()
	local absoluteCmd = self.LIB:GetName()
	local prefix = nil

	if isClient then
		if CLIENT then
			prefix = "cl"
		end
	end

	if isServer then
		if SERVER then
			prefix = "sv"
		end
	end

	if not prefix then
		return
	end

	absoluteCmd = prefix .. "_" .. absoluteCmd

	if relativeCmd ~= "" then
		absoluteCmd = absoluteCmd .. "_" .. relativeCmd
	end

	absoluteCmd = libString:SanitizeName(absoluteCmd)

	help = string.Replace(help, "##CMD##", absoluteCmd)
	help = string.Replace(help, "##CMDNAME##", relativeCmd)
	help = string.Replace(help, "##PROJECTNAME##", projecttitle)

	g_CMD = g_CMD or {}
	g_CMD[absoluteCmd] = {
		relativeCmd = relativeCmd,
		callback = callback,
		help = help
	}

	concommand.Remove(absoluteCmd)
	concommand.Add(absoluteCmd, function(ply, cmd, args, argStr)
		local cmdItem = g_CMD[cmd] or {}
		local func = cmdItem.callback

		if not isfunction(func) then
			libPrint:errorf("callback for '%s' is invalid!", 0, cmd)
		end

		func(ply, args, relativeCmd, cmd, argStr)
	end, nil, help, flags)
end

function LIB:PrintList()
	local colDefault = libColor:GetColor("default")
	local colInfo = libColor:GetColor("info")

	libPrint:printcc("\n")

	for absoluteCmd, cmdItem in SortedPairs(g_CMD) do
		local help = tostring(cmdItem.help or "")

		if help == "" then
			help = "(No description provided)"
		end

		local lines = libString:GetLines(help)

		libPrint:printcc(colInfo, absoluteCmd, ":\n")

		for k, v in ipairs(lines) do
			libPrint:printcc(colDefault, "\t", colDefault, v, "\n")
		end

		libPrint:printcc("\n")
	end
end


return LIB
