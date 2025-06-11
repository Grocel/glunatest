local libSimplediff = nil
local libSystem = nil

local LIB = {}

do -- scope
	local null = 0xFFFD
	local dot = 0x00B7
	local line = 0x2500
	local arrow = 0x003E

	local newlinemarker = 0x00B6
	local carriagereturnmarker = 0x00AC

	local verticalline = 0x2502

	LIB.UTF8_VERTICAL_LINE = utf8.char(verticalline)
	LIB.UTF8_SPACEDOT = utf8.char(dot)
	LIB.UTF8_TABLINE = utf8.char(line, line, line, arrow)
	LIB.UTF8_NEWLINE_LINUX = utf8.char(newlinemarker)
	LIB.UTF8_NEWLINE_OSX = utf8.char(carriagereturnmarker)
	LIB.UTF8_NEWLINE_WINDOWS = utf8.char(carriagereturnmarker, newlinemarker)

	LIB.UTF8_NULLBYTE = utf8.char(null)
end

LIB.DIFF_ADDED = "+"
LIB.DIFF_REMOVED = "-"
LIB.DIFF_UNCHANGED = "="

function LIB:Load(lib)
	libSimplediff = lib.simplediff
	libSystem = lib.system
end

function LIB:NormalizeNewlines(text, nl)
	nl = tostring(nl or "")
	text = tostring(text or "")

	local replacemap = {
		["\r\n"] = true,
		["\r"] = true,
		["\n"] = true,
	}

	if not replacemap[nl] then
		nl = "\n"
	end

	replacemap[nl] = nil

	for k, v in pairs(replacemap) do
		replacemap[k] = nl
	end

	text = string.gsub(text, "([\r]?[\n]?)", replacemap)

	return text
end

function LIB:NormalizeSlashes(text)
	text = tostring(text or "")

	text = string.gsub(text, "[%\\%/]+", "/")

	return text
end

function LIB:SanitizeName(text)
	text = tostring(text or "")
	text = string.Trim(text)
	text = string.lower(text)

	text = string.gsub(text, "%s+" , "_")
	text = string.gsub(text, "%c+" , "")
	text = string.gsub(text, "[^%w_%-%.]" , "-")

	return text
end

function LIB:SanitizeFunctionName(text)
	text = tostring(text or "")
	text = string.Trim(text)

	text = string.gsub(text, "%s+" , "_")
	text = string.gsub(text, "%c+" , "")
	text = string.gsub(text, "[^%w_]" , "")

	return text
end

function LIB:FromHex(str)
	str = tostring(str or "")

	str = string.upper(str)
	str = string.gsub(str, "%s+" , "")
	str = string.gsub(str, "^0X" , "")

	if (#str % 2) ~= 0 then
		str = "0" .. str
	end

	return (str:gsub('..', function(cc)
		local c = tonumber(cc, 16)
		if not c then
			error("invalid hex string")
		end

	    return string.char(c)
	end))
end

function LIB:ToHex(str)
	str = tostring(str or "")

	return (str:gsub('.', function(c)
		return string.format('%02X', string.byte(c))
	end))
end

function LIB:PatternEscape(str)
	local str = string.gsub(str, "([^%w%s])", "%%%1")
	return str
end

function LIB:PatternUnescape(str)
	local str = string.gsub(str, "%%([^%w%s])", "%1")
	return str
end

local ParseTestSummeryPattern = [[
---- Testing finished in ([%d]+.[%d]+[%s]*[%a]+), with ([%d]+) assertion(s) ----
   ([%d]+) passed, ([%d]+) failed, ([%d]+) error(s), ([%d]+) skipped.
]]

ParseTestSummeryPattern = string.Trim(ParseTestSummeryPattern)
ParseTestSummeryPattern = string.lower(ParseTestSummeryPattern)

ParseTestSummeryPattern = string.gsub(ParseTestSummeryPattern, "[%s]+" , "[%%%s]*")
ParseTestSummeryPattern = string.gsub(ParseTestSummeryPattern, "%-%-%-%-" , "%%%-%%%-%%%-%%%-")
ParseTestSummeryPattern = string.gsub(ParseTestSummeryPattern, "%(s%)" , "%%%(s%%%)")
ParseTestSummeryPattern = string.gsub(ParseTestSummeryPattern, "skipped%." , "skipped%%%.")

local ParseTestSummeryTimeUnits = {
	ms = 1 / 1000,
	s = 1,
}

function LIB:ParseTestSummery(text)
	text = tostring(text or "")
	text = string.lower(text)
	text = string.Trim(text)

	local time, assertions,
	      passed, failed,
	      errors, skipped = string.match(text, ParseTestSummeryPattern)

	if not time then
		return nil
	end

	if not assertions then
		return nil
	end

	if not passed then
		return nil
	end

	if not failed then
		return nil
	end

	if not errors then
		return nil
	end

	if not skipped then
		return nil
	end

	local t, unit =  string.match(time, "([%d.]+)[%s]*([%a]+)")

	if not t then
		return nil
	end

	if not unit then
		return nil
	end

	local factor = ParseTestSummeryTimeUnits[unit]

	if not factor then
		return nil
	end

	time = tonumber(t) or 0
	time = time * factor

	local values = {
		time = time,
		assertions = tonumber(assertions) or 0,
		passed = tonumber(passed) or 0,
		failed = tonumber(failed) or 0,
		errors = tonumber(errors) or 0,
		skipped = tonumber(skipped) or 0,
	}

	return values
end

function LIB:GetLines(text)
	text = self:NormalizeNewlines(text)

	local lines = string.Explode("\n", text, false)
	return lines
end

function LIB:Diff(old, new)
	old = self:GetLines(old)
	new = self:GetLines(new)

	return libSimplediff.diff(old, new)
end

function LIB:LimitString(text, utf8max, dots)
	text = tostring(text or "")
	dots = tostring(dots or "...")

	if text == "" then
		return ""
	end

	text = utf8.force(text)
	utf8max = tonumber(utf8max or 0) or 0

	if utf8max <= 0 then
		utf8max = 1
	end


	local utf8dotslen = utf8.len(dots)
	local utf8len = utf8.len(text)

	if utf8max >= utf8len then
		return text
	end

	local max = utf8.offset(text, utf8max)
	if not max then
		return text
	end

	max = max - 1

	if utf8len > (utf8max + utf8dotslen) then
		return string.sub(text, 1, max) .. dots
	end

	return text
end

local function escapeUtf8ReplacementChar(text, urf8char)
	return string.Replace(text, urf8char, "\\" .. urf8char)
end

function LIB:ReplaceWhiteSpace(text, usedots, keepnl, escapeUtf8Replacements)
	text = tostring(text or "")

	if keepnl == nil then
		keepnl = true
	end

	if usedots == nil then
		usedots = true
	end

	if escapeUtf8Replacements == nil then
		escapeUtf8Replacements = true
	end

	if usedots then
		if escapeUtf8Replacements then
			text = escapeUtf8ReplacementChar(text, self.UTF8_SPACEDOT)
		end

		text = string.Replace(text, " ", self.UTF8_SPACEDOT)
	end

	if escapeUtf8Replacements then
		text = escapeUtf8ReplacementChar(text, self.UTF8_TABLINE)
	end

	if escapeUtf8Replacements then
		text = escapeUtf8ReplacementChar(text, self.UTF8_NULLBYTE)
	end

	text = string.Replace(text, "\x00", self.UTF8_NULLBYTE)
	text = string.Replace(text, "\t", self.UTF8_TABLINE)

	text = self:ReplaceNewlines(text, keepnl, escapeUtf8Replacements)
	return text
end

function LIB:ReplaceNewlines(text, keepnl, escapeUtf8Replacements)
	text = tostring(text or "")

	if keepnl == nil then
		keepnl = true
	end

	if escapeUtf8Replacements == nil then
		escapeUtf8Replacements = true
	end

	local replacemap = {}

	if keepnl then
		replacemap["\r\n"] = self.UTF8_NEWLINE_WINDOWS .. "\r\n"
		replacemap["\r"] = self.UTF8_NEWLINE_OSX .. "\r"
		replacemap["\n"] = self.UTF8_NEWLINE_LINUX .. "\n"
	else
		replacemap["\r\n"] = self.UTF8_NEWLINE_WINDOWS
		replacemap["\r"] = self.UTF8_NEWLINE_OSX
		replacemap["\n"] = self.UTF8_NEWLINE_LINUX
	end

	if escapeUtf8Replacements then
		text = escapeUtf8ReplacementChar(text, self.UTF8_NEWLINE_LINUX)
		text = escapeUtf8ReplacementChar(text, self.UTF8_NEWLINE_OSX)
		text = escapeUtf8ReplacementChar(text, self.UTF8_NEWLINE_WINDOWS)
	end

	text = string.gsub(text, "([\r]?[\n]?)" , replacemap)

	return text
end

function LIB:Trim(text)
	local trimlist = {
		self.UTF8_NEWLINE_WINDOWS,
		self.UTF8_NEWLINE_OSX,
		self.UTF8_NEWLINE_LINUX,
		self.UTF8_SPACEDOT,
		self.UTF8_TABLINE,
	}

	for k, v in ipairs(trimlist) do
		trimlist[k] = string.gsub(v, "(.)" , "%%%1")
	end

	local oldtext = text

	while true do
		local newtext = oldtext

		for k, v in ipairs(trimlist) do
			local match  = string.match( newtext, "^[" .. v .. "]*(.-)[" .. v .. "]*$" )

			newtext = match or newtext
			newtext = string.Trim(newtext)
		end

		if newtext == oldtext then
			return newtext
		end

		oldtext = newtext
	end

	return oldtext
end

function LIB:PadRight(str, len, fill)
	str = tostring(str or "")
	fill = tostring(fill or "")
	len = tonumber(len or 0) or 0

	if len <= 0 then
		return ""
	end

	local slen = utf8.len(str)

	if slen == len then
		return str
	end

	if slen > len then
		return string.sub(str, 1, len)
	end

	if fill == "" then
		fill = " "
	end

	return str .. string.rep(fill, len - slen)
end

function LIB:PadLeft(str, len, fill)
	str = tostring(str or "")
	fill = tostring(fill or "")
	len = tonumber(len or 0) or 0

	if len <= 0 then
		return ""
	end

	local slen = utf8.len(str)

	if slen == len then
		return str
	end

	if slen > len then
		return string.sub(str, -len)
	end

	if fill == "" then
		fill = " "
	end

	return string.rep(fill, len - slen) .. str
end

function LIB:SideBySide(borderstr, ...)
	borderstr = tostring(borderstr or "")
	local args = {...}

	local linesTable = {}
	local lineCount = 0

	for i, v in ipairs(args) do
		local lines = self:GetLines(v)
		local len = #lines

		if len > lineCount then
			lineCount = len
		end

		local longestLineLen = 0

		for l, line in ipairs(lines) do
			line = string.Replace(line, "\t", "    ")
			local lineLen = utf8.len(line)

			if lineLen > longestLineLen then
				longestLineLen = lineLen
			end

			lines[l] = line
		end

		lines.longestLineLen = longestLineLen
		linesTable[#linesTable + 1] = lines
	end

	if lineCount <= 0 then
		return ""
	end

	local combinedlines = {}

	for l = 1, lineCount do
		local combinedline = {}

		for j, v in ipairs(linesTable) do
			local line = tostring(v[l] or "")

			if j < #linesTable then
				line = self:PadRight(line, v.longestLineLen, " ")
			end

			combinedline[#combinedline + 1] = line
		end

		combinedline = table.concat(combinedline, borderstr)
		combinedline = string.TrimRight(combinedline)

		combinedlines[#combinedlines + 1] = combinedline
	end

	combinedlines = table.concat(combinedlines, "\n")
	combinedlines = string.TrimRight(combinedlines)

	return combinedlines
end


return LIB
