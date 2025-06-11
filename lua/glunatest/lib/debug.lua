local libString = nil
local libFile = nil

local LIB = {}

LIB.MAXSTACKSIZE = 1000

function LIB:Load(lib)
	libString = lib.string
	libFile = lib.file
end

function LIB:Traceback(...)
	local args = {...}
	local argsn = #args

	level = 1
	message = ""

	if argsn == 1 then
		local arg1 = args[1]

		if isnumber(arg1) then
			level = arg1
		else
			message = tostring(arg1 or "")
		end

	elseif argsn == 2 then
		local arg1 = args[1]
		local arg2 = args[2]

		message = tostring(arg1 or "")
		level = tonumber(arg2 or 1) or 1
	elseif argsn > 2 then
		error("bad call of traceback, more than 2 arguments")
	end

	if level < 1 then
		error("bad stack level")
	end

	local function getline(line)
		local info = debug.getinfo(level + line + 2, "lnS")

		if not info then
			return nil
		end

		local name = info.name or ""

		if name == "" then
			name = "(anonymous)"
		end

		local what = info.what or ""

		if what == "" then
			what = "?"
		end

		local source = info.short_src or ""

		if source == "" then
			source = info.source or ""
		end

		if source == "" then
			source = "(unknown)"
		end

		local currentline = info.currentline or -1

		local output = string.format("    %4d. %s:%d <%s function '%s'>", line, source, currentline, what, name)
		return output
	end

	local i = 0
	local err = ""
	local stack = {}

	while true do
		i = i + 1

		if i > self.MAXSTACKSIZE then
			error("stack overflow")
			break
		end

		local status, outout = xpcall(getline, function(thiserr)
			err = tostring(thiserr or "")
			err = string.Trim(err)
		end, i)

		if not status then
			error(err)
		end

		if not outout then
			break
		end

		stack[i] = outout
	end

	local output = message

	if output ~= "" then
		output = output .. "\n"
	end

	output = output .. "stack traceback:\n"
	output = output .. table.concat(stack, "\n")

	return output
end

function LIB:LogToFile(path, append, ...)
	path = libFile:ResolvePath(path, "LOG")

	if append == nil then
		append = true
	end

	local timestamp = os.time()
	local timeFileString = os.date("%Y-%m-%d.txt" , timestamp)
	local timeString = os.date("[%Y-%m-%d %H:%M:%S] ", timestamp)

	if not path then
		path = libFile:ResolvePath(timeFileString, "LOG")
	end

	local tab = {...}
	local output = ""

	for i, v in ipairs(tab) do
		output[#output + 1] = tostring(v)
	end

	output = timeString .. table.concat(output, "\t") .. "\n"

	if append then
		libFile:Append(path, output)
	else
		libFile:Write(path, output)
	end
end

function LIB:Log(...)
	self:LogToFile(nil, true, ...)
end

return LIB
