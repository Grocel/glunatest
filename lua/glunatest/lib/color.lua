local libSystem = nil
local libTable = nil

local LIB = {}
LIB.COLORS = {}
LIB.COLORMODE = "DEFAULT"

function LIB:Load(lib)
	libSystem = lib.system
	libTable = lib.table
end

function LIB:Ready(lib)
	self.COLORMODE = "DEFAULT"

	if libSystem:IsWindowsCLI() then
		self.COLORMODE = "WINDOWS_CMD_COLOR16"
	end

	if libSystem:IsLinuxCLI() then
		self.COLORMODE = "ANSI_COLOR256"
	end

	local configColorMode = nil

	if libSystem:IsCLI() then
		configColorMode = lib:GetConfig("plattform", "cli", "colormode")
	else
		configColorMode = lib:GetConfig("plattform", "ingame", "colormode")
	end

	configColorMode = tostring(configColorMode or "")

	if configColorMode ~= "" then
		self.COLORMODE = configColorMode
	end

	self.COLORS.DEFAULT = {
		default = Color(216, 216, 216),
		error = Color(255, 96, 96),
		fail = Color(255, 128, 64),
		warning = Color(255, 192, 64),
		skip = Color(255, 255, 100),
		ok = Color(128, 255, 128),
		info = Color(102, 153, 255),
		summary = Color(150, 200, 255),
		exit = Color(200, 150, 255),
	}

	self.COLORS.ANSI_TRUE_COLOR = table.Copy(self.COLORS.DEFAULT)
	self.COLORS.ANSI_COLOR256 = table.Copy(self.COLORS.DEFAULT)

	// https://blogs.msdn.microsoft.com/commandline/2017/08/02/updating-the-windows-console-colors/
	local WINCMD_BLACK           = Color(0, 0, 0)
	local WINCMD_DARK_BLUE       = Color(0, 0, 192)
	local WINCMD_DARK_GREEN      = Color(0, 192, 0)
	local WINCMD_DARK_CYAN       = Color(0, 192, 192)
	local WINCMD_DARK_RED        = Color(192, 0, 0)
	local WINCMD_DARK_MAGENTA    = Color(192, 0, 192)
	local WINCMD_DARK_YELLOW     = Color(192, 192, 0)
	local WINCMD_DARK_WHITE      = Color(192, 192, 192)

	local WINCMD_BRIGHT_BLACK    = Color(128, 128, 128)
	local WINCMD_BRIGHT_BLUE     = Color(0, 0, 255)
	local WINCMD_BRIGHT_GREEN    = Color(0, 255, 0)
	local WINCMD_BRIGHT_CYAN     = Color(0, 255, 255)
	local WINCMD_BRIGHT_RED      = Color(255, 0, 0)
	local WINCMD_BRIGHT_MAGENTA  = Color(255, 0, 255)
	local WINCMD_BRIGHT_YELLOW   = Color(255, 255, 0)
	local WINCMD_WHITE           = Color(255, 255, 255)

	self.COLORS.WINDOWS_CMD_COLOR16 = {
		default = WINCMD_DARK_WHITE,
		error = WINCMD_BRIGHT_RED,
		fail = WINCMD_BRIGHT_YELLOW,
		warning = WINCMD_DARK_YELLOW,
		skip = WINCMD_DARK_YELLOW,
		ok = WINCMD_BRIGHT_GREEN,
		info = WINCMD_DARK_CYAN,
		summary = WINCMD_BRIGHT_CYAN,
		exit = WINCMD_BRIGHT_MAGENTA,
	}

	self.COLORS.ANSI_WINDOWS_CMD_COLOR256 = table.Copy(self.COLORS.WINDOWS_CMD_COLOR16)

	self.COLORS.ANSI_COLOR16 = table.Copy(self.COLORS.WINDOWS_CMD_COLOR16)
	self.COLORS.ANSI_COLOR16.info = Color(0, 128, 128)
	self.COLORS.ANSI_COLOR16.ok = Color(0, 255, 0)
	self.COLORS.ANSI_COLOR16.skip = Color(128, 128, 0)
	self.COLORS.ANSI_COLOR16.warning = Color(128, 128, 0)

	self.COLORS.ANSI_COLOR8 = table.Copy(self.COLORS.WINDOWS_CMD_COLOR16)
	self.COLORS.ANSI_COLOR8.info = Color(0, 0, 128)
end

function LIB:GetColorMode(overrideColorMode)
	local curColorMode = tostring(overrideColorMode or "")

	if curColorMode == "" then
		curColorMode = self.COLORMODE or ""
	end

	curColorMode = string.upper(curColorMode)

	if curColorMode == "NONE" then
		return "NONE"
	end

	return self.COLORS[curColorMode] and curColorMode or "DEFAULT"
end


function LIB:GetColorProfile(overrideColorMode)
	local curColorMode = self:GetColorMode(overrideColorMode)

	if curColorMode == "NONE" then
		return nil
	end

	local colors = self.COLORS[curColorMode] or {}
	return colors
end

function LIB:GetColor(colorOrName, overrideColorMode)
	local curColorMode = self:GetColorMode(overrideColorMode)

	if curColorMode == "NONE" then
		return Color(255, 255, 255)
	end

	if IsColor(colorOrName) then
		return colorOrName
	end

	if istable(colorOrName) and colorOrName.r then
		return Color(
			tonumber(colorOrName.r or 0) or 0,
			tonumber(colorOrName.g or 0) or 0,
			tonumber(colorOrName.b or 0) or 0,
			tonumber(colorOrName.a or 255) or 255
		)
	end

	colorOrName = tostring(colorOrName or "")
	colorOrName = string.lower(colorOrName)

	local colors = self:GetColorProfile(overrideColorMode)
	if not colors then
		return Color(255, 255, 255)
	end

	local color = colors[colorOrName] or colors.default or Color(0, 255, 255)

	return color
end


local convertFuncs = {}

convertFuncs.ANSI_TRUE_COLOR = function(color)
	return {38, 2, color.r, color.g, color.b}
end

convertFuncs.ANSI_COLOR256 = function(color)
	local r = color.r
	local g = color.g
	local b = color.b

	// extended greyscale palette
	if r == g and g == b then
		if r < 8 then
			return {38, 5, 16}
		end

		if r > 248 then
			return {38, 5, 231}
		end

		local ansi = math.Round(((r - 8) / 247) * 24) + 232
		return {38, 5, ansi}
	end

	local ansi = 16
	ansi = ansi + (36 * math.Round(r / 255 * 5))
	ansi = ansi + (6 * math.Round(g / 255 * 5))
	ansi = ansi + math.Round(b / 255 * 5)

	return {38, 5, ansi}
end

convertFuncs.ANSI_WINDOWS_CMD_COLOR256 = convertFuncs.ANSI_COLOR256


convertFuncs.ANSI_COLOR16 = function(color)
	local ansicode = convertFuncs.ANSI_COLOR8(color)

	local h, s, v = ColorToHSV(color)
	v = math.Round(v / 0.5);

	local brighter = 0

	if v >= 2 then
		brighter = 1
	end

	return {brighter, ansicode[1]}
end

convertFuncs.ANSI_COLOR8 = function(color)
	local r = color.r
	local g = color.g
	local b = color.b

	local h, s, v = ColorToHSV(color)
	v = math.Round(v / 0.5);

	if v <= 0 then
		return {30}
	end

	local ansi = 30
	ansi = ansi + (math.Round(b / 255) * 4)
	ansi = ansi + (math.Round(g / 255) * 2)
	ansi = ansi + math.Round(r / 255);

	return {ansi}
end

LIB.ANSI_START = "\x1B["
LIB.ANSI_END = "m"
LIB.ANSI_RESET = LIB.ANSI_START .. "0" .. LIB.ANSI_END

local ansipattern = LIB.ANSI_START .. "%s" .. LIB.ANSI_END

function LIB:ColorToANSI(colorOrName, text, overrideColorMode)
	local color = self:GetColor(colorOrName, overrideColorMode)

	local curColorMode = self:GetColorMode(overrideColorMode)
	if curColorMode == "NONE" then
		if text then
			text = tostring(text or "")
			return text
		end

		return ""
	end

	local convertFunc = convertFuncs[curColorMode]
	local code = nil

	if convertFunc then
		code = convertFunc(color)
	end

	if not code then
		if text then
			text = tostring(text or "")
			return text
		end

		return ""
	end

	code = table.concat(code, ";");
	ansi = string.format(ansipattern, code)

	if text then
		text = tostring(text or "")
		text = ansi .. text .. self.ANSI_RESET

		return text
	end

	return ansi
end

function LIB:GetANSIReset()
	return self.ANSI_RESET
end

function LIB:PrintTest(colormode)
	colormode = self:GetColorMode(colormode)

	local block = utf8.char(0x2588)

	local fallbackcol = Color(255, 255, 255)

	local isWindowsCLI = self.LIB.system:IsWindowsCLI()
	local isLinuxCLI = self.LIB.system:IsLinuxCLI()

	local MsgCPrint = function(c, s)
		if isLinuxCLI then
			Msg(self:ColorToANSI(c, s))
			return
		end

		MsgC(c, s)
	end

	local printcolor = function(c)
		local bbb = block .. block .. block

		MsgCPrint(c, bbb)
		MsgCPrint(fallbackcol, string.format("%3d, %3d, %3d", c.r, c.g, c.b))
		MsgCPrint(c, bbb)
	end

	local printTestTable = function(e, f, l, mode)
		e = e or 1
		f = f or 0
		l = l or 1

		MsgN("")
		MsgN(mode or "")
		MsgN("")

		for r = f, 255 - f, e do
			for g = f, 255 - f, e do
				for b = f, 255 - f, e do
					local r = math.Clamp(r, 0, 255)
					local b = math.Clamp(b, 0, 255)
					local g = math.Clamp(g, 0, 255)

					printcolor(Color(r, g, b))
				end
				MsgN("")
			end
		end

		MsgN("")
		MsgN("")

		for x = 0, 255, l do
			local x = math.Clamp(x, 0, 255)

			printcolor(Color(x, x, x))
			printcolor(Color(x, x, 0))
			printcolor(Color(x, 0, x))
			printcolor(Color(x, 0, 0))
			printcolor(Color(0, x, x))
			printcolor(Color(0, x, 0))
			printcolor(Color(0, 0, x))
			MsgN("")
		end

		MsgN("")
		MsgN("")

		local colors = self:GetColorProfile()

		for name, color in SortedPairs(colors or {}) do
			MsgCPrint(color, block .. string.format(" %-34s: %3d, %3d, %3d ", mode .. "/" .. name, color.r, color.g, color.b) .. block)
			MsgN("")
		end

		MsgN("")
		MsgN("")
		MsgN("")
	end

	local oldmode = self.COLORMODE
	self.COLORMODE = colormode

	printTestTable(32, 0, 8, self.COLORMODE)

	self.COLORMODE = oldmode
end

return LIB
