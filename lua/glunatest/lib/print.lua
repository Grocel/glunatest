local libString = nil
local libSystem = nil
local libColor = nil

local oldlevel = 1
local dotsInLine = 0
local oldendedwithnl = true
local stringMatch = string.match
local stringFormat = string.format
local stringFind = string.find

local tostring = tostring
local MsgC = MsgC
local Msg = Msg

local LIB = {}
LIB.MaxDotsPerLine = 80

function LIB:Load(lib)
	libString = lib.string
	libSystem = lib.system
	libColor = lib.color
end

local function printc(color, ...)
	local output = {...}

	for i, v in ipairs(output) do
		output[i] = tostring(v or "")
	end

	output = table.concat(output)

	if not libSystem:IsLinuxCLI() then
		MsgC(color, output)
		return
	end

	Msg(libColor:ColorToANSI(color, output))
end



function LIB:PrintTestData(color, data, level, isdot, intest)
	color = libColor:GetColor(color)
	color_default = libColor:GetColor("default")

	data = tostring(data)
	level = level or 1
	isdot = isdot or false

	local levelIncreased = level > oldlevel
	local levelChanged = level ~= oldlevel

	oldlevel = level

	if isdot then
		if levelChanged then
			dotsInLine = 0
		else
			dotsInLine = dotsInLine + 1
		end
	else
		dotsInLine = 0
	end

	local text = data

	if isdot && dotsInLine >= self.MaxDotsPerLine then
		text = text .. "\n";
		dotsInLine = 0
	end

	local lastendedwithnl = oldendedwithnl

	local hasnl = stringMatch(text, "\n")
	local endedwithnl = text[#text] == "\n"
	oldendedwithnl = endedwithnl

	local forceln = false

	if levelIncreased then
		forceln = not lastendedwithnl
	end

	if color == color_default and not intest then
		if stringMatch(text, "^%s*ERROR") then
			color = libColor:GetColor("error")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*Error") then
			color = libColor:GetColor("error")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*%*%s*Error") then
			color = libColor:GetColor("error")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*FAIL") then
			color = libColor:GetColor("fail")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*WARNING") then
			color = libColor:GetColor("warning")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*SKIP") then
			color = libColor:GetColor("skip")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*PASS") then
			color = libColor:GetColor("ok")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*%-%- ") then
			color = libColor:GetColor("info")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*%-%-%-%- ") then
			color = libColor:GetColor("summary")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*Finished suite ") then
			color = libColor:GetColor("summary")
			forceln = not lastendedwithnl
		end

		if stringMatch(text, "^%s*Starting tests, ") then
			color = libColor:GetColor("summary")
			forceln = not lastendedwithnl
		end
	end

	color = libColor:GetColor(color)

	if not hasnl and not lastendedwithnl and not forceln then
		printc(color, data)
		return
	end

	local prefix = string.rep("    ", level) .. libString.UTF8_VERTICAL_LINE .. " "

	text = string.gsub(text, "\r\n", "\n")
	text = string.gsub(text, "\r", "\n")

	if forceln then
		text = "\n" .. text
	end

	local lines = string.Explode("\n", text, false)

	if endedwithnl then
		lines[#lines] = nil
	end

	local linecount = #lines

	if lastendedwithnl then
		printc(color_default, prefix)
	end

	for i, v in ipairs(lines) do
		if i > 1 then
			printc(color_default, prefix)
		end

		printc(color, v)

		if i < linecount then
			printc(color_default, "\n")
		end
	end

	if endedwithnl then
		printc(color_default, "\n")
	end
end

function LIB:printcc(...)
	local lastcol = libColor:GetColor("default")

	for i, v in ipairs({...}) do
		if IsColor(v) then
			lastcol = libColor:GetColor(v)
			continue
		end

		if istable(v) and v.r then
			lastcol = libColor:GetColor(v)
			continue
		end

		printc(lastcol, tostring(v))
	end
end

function LIB:printc(color, ...)
	color = libColor:GetColor(color)

	local args = {}

	for i, v in ipairs({...}) do
		args[#args + 1] = tostring(v)
	end

	local lines = table.concat(args, "\t")
	lines = libString:GetLines(lines)

	for i, v in ipairs(lines) do
		printc(color, v, "\n")
	end
end

function LIB:printcf(color, format, ...)
	format = tostring(format or "")

	self:printc(color, stringFormat(format, ...))
end

function LIB:print(...)
	color_default = libColor:GetColor("default")
	self:printc(color_default, ...)
end

function LIB:printf(format, ...)
	format = tostring(format or "")

	self:print(stringFormat(format, ...))
end

function LIB:error(err, level)
	err = tostring(err or "")
	level = tonumber(level or 0) or 0

	if level <= 0 then
		level = 1
	end

	error(err, level + 1)
end

function LIB:errorf(format, level, ...)
	format = tostring(format or "")
	level = tonumber(level or 0) or 0

	if level <= 0 then
		level = 1
	end

	self:error(stringFormat(format, ...), level + 1)
end

function LIB:warn(err)
	err = libString:GetLines(err)

	for i, v in ipairs(err) do
		ErrorNoHalt(v .. "\n")
	end
end

function LIB:warnf(format, ...)
	format = tostring(format or "")
	self:warn(stringFormat(format, ...))
end

function LIB:ProcessDiffResult(diff, settings)
	diff = diff or {}
	settings = settings or {}

	local UNCHANGED = libString.DIFF_UNCHANGED

	local MAXLASTLINES = settings.maxlastlines or 5
	local MAXLASTEMPTYLINES = settings.maxlastemptylines or 3

	local MAXNEXTLINES = settings.maxnextlines or 5
	local MAXNEXTEMPTYLINES = settings.maxnextemptylines or 3

	local MAXDIFFBLOCKS = settings.maxdiffblocks or 8
	local MAXDIFFSIZE = settings.maxdiffsize or 16

	local reasonlines = {}
	local linesdone = {}

	local currentlinenumber = 0
	local lastlinenumber = 0
	local nextlinenumber = 0

	local errordiffblocks = 0
	local errordiffhiddenblocks = 0

	local lastprintedlinenumber = 0

	local function addDotsToBuffer(linenumber)
		if lastprintedlinenumber > 0 then
			if (linenumber - lastprintedlinenumber) > 1 then
				reasonlines[#reasonlines + 1] = "\n     ...\n"
			end
		end

		lastprintedlinenumber = linenumber
	end

	local function addLineToBuffer(linenumber, mode, line)
		addDotsToBuffer(linenumber)

		reasonlines[#reasonlines + 1] = stringFormat("%6d %1s%s", linenumber, mode, line)
		linesdone[linenumber] = true
	end

	local function addSkippedToBuffer(linenumber, linecount, mode)
		if linecount <= 0 then
			return
		end

		if mode == "" then
			return
		end

		if mode == UNCHANGED then
			return
		end

		local format = "       %1s %d lines starting at line %d"

		if linecount == 1 then
			format = "       %1s %d line at line %d"
		end

		reasonlines[#reasonlines + 1] = stringFormat(format, mode, linecount, linenumber)
	end

	for k, block in ipairs(diff) do
		local mode = block[1]
		local lines = block[2]

		local lastblock = diff[k - 1] or {}
		local nextblock = diff[k + 1] or {}

		local lastmode = lastblock[1] or ""
		local nextmode = nextblock[1] or ""

		local lastblocklines = lastblock[2] or {}
		local nextblocklines = nextblock[2] or {}

		local size = #lines
		local lastsize = #lastblocklines
		local nextsize = #nextblocklines

		nextlinenumber = currentlinenumber + #lines

		if MAXDIFFBLOCKS > 0 then
			if errordiffblocks >= MAXDIFFBLOCKS then

				if mode ~= UNCHANGED then
					if nextmode == UNCHANGED or nextmode == "" then
						errordiffblocks = errordiffblocks + 1
						errordiffhiddenblocks = errordiffhiddenblocks + 1
					end
				end

				continue
			end
		end

		-- add the last unchanged lines before the changed block
		if lastmode ~= mode and lastmode == UNCHANGED then
			local lastlines = {}
			local lastlinecount = 0
			local lastemptylinecount = 0

			for i = #lastblocklines, 1, -1 do

				local line = lastblocklines[i] or ""
				local linetrimmed = libString:Trim(line)
				local empty = linetrimmed == ""
				local linenumber = lastlinenumber + i

				if empty then
					lastemptylinecount = lastemptylinecount + 1
				else
					lastlinecount = lastlinecount + 1
					lastemptylinecount = 0
				end

				if MAXLASTLINES > 0 and lastlinecount > MAXLASTLINES then
					break
				end

				if MAXLASTEMPTYLINES > 0 and lastemptylinecount > MAXLASTEMPTYLINES then
					break
				end

				lastlines[#lastlines + 1] = {
					line = line,
					empty = empty,
					linenumber = linenumber,
				}
			end

			local wasempty = true

			for i = #lastlines, 1, -1 do
				local line = lastlines[i].line
				local empty = lastlines[i].empty
				local linenumber = lastlines[i].linenumber

				-- Don't add whitespace lines at the beginning
				if not empty then
					wasempty = false
				end

				if wasempty then
					continue
				end

				if linesdone[linenumber] then
					continue
				end

				addLineToBuffer(linenumber, "", line)
			end
		end

		-- changed block
		if mode ~= UNCHANGED then
			if nextmode == UNCHANGED or nextmode == "" then
				errordiffblocks = errordiffblocks + 1
			end

			local diffsize = size

			if lastmode ~= UNCHANGED then
				diffsize = diffsize + lastsize
			end

			if nextmode ~= UNCHANGED then
				diffsize = diffsize + nextsize
			end

			if MAXDIFFSIZE > 0 and diffsize > MAXDIFFSIZE then
				local linenumber = currentlinenumber + 1

				if not linesdone[linenumber] then
					addDotsToBuffer(linenumber)
					addSkippedToBuffer(linenumber, lastsize, lastmode)
					addSkippedToBuffer(linenumber, size, mode)
					addSkippedToBuffer(linenumber, nextsize, nextmode)

					linesdone[linenumber] = true
				end
			else
				for i, line in ipairs(lines) do
					local linenumber = currentlinenumber + i
					addLineToBuffer(linenumber, mode, line)
				end
			end
		end

		-- add the first unchanged lines after the changed block
		if nextmode ~= mode and nextmode == UNCHANGED then
			local nextlines = {}
			local nextlinecount = 0
			local nextemptylinecount = 0

			for i, line in ipairs(nextblocklines) do
				local linetrimmed = libString:Trim(line)
				local empty = linetrimmed == ""
				local linenumber = nextlinenumber + i

				if empty then
					nextemptylinecount = nextemptylinecount + 1
				else
					nextlinecount = nextlinecount + 1
					nextemptylinecount = 0
				end

				if MAXNEXTLINES > 0 and nextlinecount > MAXNEXTLINES then
					break
				end

				if MAXNEXTEMPTYLINES > 0 and nextemptylinecount > MAXNEXTEMPTYLINES then
					break
				end

				nextlines[#nextlines + 1] = {
					line = line,
					empty = empty,
					linenumber = linenumber,
				}
			end

			local wasempty = true

			for i = #nextlines, 1, -1 do
				local empty = nextlines[i].empty

				-- Don't add whitespace lines at the end
				if not empty then
					wasempty = false
				end

				if not wasempty then
					break
				end

				nextlines[i] = nil
			end

			for i, line in ipairs(nextlines) do
				local linenumber = line.linenumber
				local linestring = line.line

				if linesdone[linenumber] then
					continue
				end

				addLineToBuffer(linenumber, "", linestring)
			end
		end

		if mode == UNCHANGED or nextmode == UNCHANGED then
			lastlinenumber = currentlinenumber
			currentlinenumber = nextlinenumber
		end
	end

	local differences = ""

	if errordiffblocks > 0 then
		if errordiffhiddenblocks > 0 then
			differences = stringFormat("\n\n     ...\n\n  %d difference blocks found (%d hidden)", errordiffblocks, errordiffhiddenblocks)
		else
			differences = stringFormat("\n\n  %d difference blocks found", errordiffblocks)
		end
	end

	differences = table.concat(reasonlines, "\n") .. differences

	return differences, errordiffblocks, errordiffhiddenblocks
end

function LIB:ProcessEqualResult(equalStr, settings)
	equalStr = tostring(equalStr or "")

	if equalStr == "" then
		return "", 0
	end

	settings = settings or {}

	equalStr = GLunaTestLib.string:GetLines(equalStr)
	local linecount = #equalStr

	local startlines = {}
	local endlines = {}

	local skipstartline = nil
	local skippedlines = 0
	local MAXSTARTLINES = settings.maxstartlines or 16
	local MAXENDLINES = settings.maxendlines or 4

	for i, v in ipairs(equalStr) do
		if i > MAXSTARTLINES && i <= (linecount - MAXENDLINES) then
			if not skipstartline then
				skipstartline = i
			end

			skippedlines = skippedlines + 1
			continue
		end

		if i > MAXSTARTLINES && skippedlines > 0 then
			endlines[#endlines + 1] = stringFormat("%6d  %s", i, v)
		else
			startlines[#startlines + 1] = stringFormat("%6d  %s", i, v)
		end
	end

	if skippedlines > 0 then
		local format = "         %d lines hidden starting at line %d"

		if skippedlines == 1 then
			format = "         %d line hidden at line %d"
		end

		startlines[#startlines + 1] = ""
		startlines[#startlines + 1] = stringFormat(format, skippedlines, skipstartline)
		startlines[#startlines + 1] = ""
	end

	startlines[#startlines + 1] = table.concat(endlines, "\n")

	local summary = table.concat(startlines, "\n")
	return summary, skippedlines
end

local function getPadLengthForUtf8Char(c, minlen_utf8)
	local len = #c
	local len_utf8 = utf8.len(c) or 0

	if minlen_utf8 < len_utf8 then
		minlen_utf8 = len_utf8
	end

	return (len + (minlen_utf8 - len_utf8))
end

function LIB:ProcessDiffResultLegend(diffstring, rowprefixes)
	diffstring = tostring(diffstring or "")
	rowprefixes = tostring(rowprefixes or "")

	rowprefixes = string.Trim(rowprefixes)
	rowprefixes = libString:GetLines(rowprefixes)

	local checkfor = {
		{
			utf8 = libString.UTF8_NEWLINE_LINUX,
			text = "LF",
			char = "(\\n)",
		},
		{
			utf8 = libString.UTF8_NEWLINE_OSX,
			text = "CR",
			char = "(\\r)",
		},
		{
			utf8 = libString.UTF8_NEWLINE_WINDOWS,
			text = "CRLF",
			char = "(\\r\\n)",
		},
		{
			utf8 = libString.UTF8_TABLINE,
			text = "Tab",
			char = "(\\t)",
		},
		{
			utf8 = libString.UTF8_SPACEDOT,
			text = "Space",
			char = "( )",
		},
		{
			utf8 = libString.UTF8_NULLBYTE,
			text = "NULL",
			char = "(\\0)",
		},
	}

	local foundcharsRows = {}
	local foundcharsColumnSizes = {}
	local maxrows = 2
	local count = 0

	for i, v in ipairs(checkfor) do
		local found = stringFind(diffstring, v.utf8, 1, true)
		if not found then
			continue
		end

		count = count + 1

		local row = ((count - 1) % maxrows) + 1
		local column = math.ceil(count / maxrows)

		foundcharsRows[row] = foundcharsRows[row] or {}
		foundcharsRows[row][column] = v

		foundcharsColumnSizes[column] = foundcharsColumnSizes[column] or {}

		for name, str in pairs(v) do
			local len_utf8 = utf8.len(str) or 0
			foundcharsColumnSizes[column][name] = math.max(foundcharsColumnSizes[column][name] or 0, len_utf8)
		end
	end

	local rowprefixescolsize = 0

	for i, v in ipairs(rowprefixes) do
		foundcharsRows[i] = foundcharsRows[i] or {}

		local len_utf8 = utf8.len(v) or 0
		rowprefixescolsize = math.max(rowprefixescolsize, len_utf8)
	end

	local legendstring = {}

	for row, cols in ipairs(foundcharsRows) do
		local rowstring = {}
		local rowparams = {}
		local lname = ""

		if rowprefixescolsize > 0 then
			local prefix = rowprefixes[row] or ""

			rowstring[#rowstring + 1] = "%-" .. getPadLengthForUtf8Char(prefix, rowprefixescolsize + 8) .. "s"
			rowparams[#rowparams + 1] = prefix
		end

		if row == 1 and count > 0 then
			lname = "Whitespaces:"
		end

		rowstring[#rowstring + 1] = "%-" .. getPadLengthForUtf8Char(lname, 14) .. "s"
		rowparams[#rowparams + 1] = lname


		for col, cell in ipairs(cols) do
			local sizes = foundcharsColumnSizes[col]

			rowstring[#rowstring + 1] = "%-" .. getPadLengthForUtf8Char(cell.utf8, sizes.utf8) .. "s "
			rowparams[#rowparams + 1] = cell.utf8

			rowstring[#rowstring + 1] = "%-" .. getPadLengthForUtf8Char(cell.text, sizes.text) .. "s "
			rowparams[#rowparams + 1] = cell.text

			rowstring[#rowstring + 1] = "%-" .. getPadLengthForUtf8Char(cell.char, sizes.char) .. "s"
			rowparams[#rowparams + 1] = cell.char

			rowstring[#rowstring + 1] = "  "
		end

		rowstring = table.concat(rowstring)
		rowstring = stringFormat(rowstring, unpack(rowparams))

		legendstring[#legendstring + 1] = "      " .. string.TrimRight(rowstring)
	end

	legendstring = table.concat(legendstring, "\n")
	legendstring = string.TrimRight(legendstring)

	return legendstring
end

function LIB:ConvertNonPrintableAsciiChars(str)
	str = tostring(str or "")

	local nonPrintablePlaceholder = 0x00B7

	local convertMap = {}

	if not libSystem:IsWindowsCLI() then
		for i = 0x00, 0x1F, 1 do
			convertMap[i] = nonPrintablePlaceholder
		end
	end

	for i = 0x80, 0x9F, 1 do
		convertMap[i] = nonPrintablePlaceholder
	end

	convertMap[0x00] = nonPrintablePlaceholder
	convertMap[0x0D] = 0x00AC -- \r
	convertMap[0x0A] = 0x00B6 -- \n
	convertMap[0x09] = 0x003E -- \t
	convertMap[0x08] = 0x003C -- \b
	convertMap[0x07] = 0x002E -- \a
	convertMap[0x7F] = nonPrintablePlaceholder

	return (str:gsub('.', function(c)
		local b = string.byte(c)
		b = convertMap[b] or b
		b = utf8.char(b)

		return b
	end))
end

function LIB:ProcessHexResult(hex, title, settings)
	hex = tostring(hex or "")
	title = tostring(title or "")

	settings = settings or {}

	local len = #hex
	local size = len / 2

	local MAXLINES = settings.maxlines or 64
	local MAXSEGMENTLEN = settings.maxsegmentlen or 8
	local MAXSEGMENTPERLINE = settings.maxsegmentperline or 2
	local MAXLINESPERGAP = settings.maxlinespergap or 4

	local isShortened = false
	local outputHex = {}
	local outputChars = {}

	local segmentLen = MAXSEGMENTLEN
	local lineAfterSegments = MAXSEGMENTPERLINE
	local gapAfterLines = MAXLINESPERGAP

	local segments = math.ceil(len / segmentLen)
	local hasTitle = title ~= ""

	local maxDecimalPlaces = math.log10(#hex)
	maxDecimalPlaces = math.ceil(maxDecimalPlaces)

	if maxDecimalPlaces < 1 then
		maxDecimalPlaces = 1
	end

	if maxDecimalPlaces > 9 then
		maxDecimalPlaces = 9
	end

	if hasTitle then
		outputHex[#outputHex + 1] = title
		outputHex[#outputHex + 1] = "\n"
		outputHex[#outputHex + 1] = "\n"
		outputChars[#outputChars + 1] = "\n"
		outputChars[#outputChars + 1] = "\n"
	end

	local wasnewline = true
	local line = 1

	for segment = 1, segments, 1 do
		local start = (segment - 1) * segmentLen
		local newline = (segment % lineAfterSegments) == 0
		local newgab = (line % gapAfterLines) == 0

		if wasnewline then
			if hasTitle then
				outputHex[#outputHex + 1] = "  "
			end

			outputHex[#outputHex + 1] = stringFormat("%" .. maxDecimalPlaces .. "d: ", start / 2)
		end

		local segmentStr = string.sub(hex, start + 1, start + segmentLen)

		outputHex[#outputHex + 1] = segmentStr

		segmentStr = self:ConvertNonPrintableAsciiChars(libString:FromHex(segmentStr))
		outputChars[#outputChars + 1] = segmentStr

		if newline then
			outputHex[#outputHex + 1] = "\n"
			outputChars[#outputChars + 1] = "\n"

			if newgab then
				outputHex[#outputHex + 1] = "\n"
				outputChars[#outputChars + 1] = "\n"
			end

			wasnewline = true

			line = line + 1
			if line > MAXLINES then
				isShortened = true
				break
			end
		else
			outputHex[#outputHex + 1] = " "
			outputChars[#outputChars + 1] = " "
			wasnewline = false
		end
	end

	outputHex = table.concat(outputHex)
	outputHex = {string.TrimRight(outputHex)}

	outputChars = table.concat(outputChars)
	outputChars = {string.TrimRight(outputChars)}

	if isShortened then
		outputHex[#outputHex + 1] = "\n"
		outputHex[#outputHex + 1] = "\n"
		outputHex[#outputHex + 1] = string.rep(" ", maxDecimalPlaces)
		outputHex[#outputHex + 1] = "    "
		outputHex[#outputHex + 1] = "..."
		outputChars[#outputChars + 1] = "\n"
		outputChars[#outputChars + 1] = "\n"
		outputChars[#outputChars + 1] = "..."
	end

	outputHex[#outputHex + 1] = "\n"
	outputHex[#outputHex + 1] = "\n"
	outputHex[#outputHex + 1] = stringFormat("%d Byte(s)", size)

	outputHex = table.concat(outputHex)
	outputChars = table.concat(outputChars)

	local output = libString:SideBySide("   ", outputHex, outputChars)

	return output
end

return LIB
