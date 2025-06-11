local libTimer = nil
local libString = nil
local libMemory = nil

local CLASS = {}

function CLASS:ClassLoad(classLib)
	libTimer = classLib.LIB.timer
	libString = classLib.LIB.string
	libMemory = classLib.LIB.memory
end

function CLASS:Create()
	self.Valid = true
	self._markedforremove = false

	self.Name = ""
	self._CreateRemoveTimerName = "ClassCreateRemoveTimer[" .. self:GetClassname() .. "][" .. self:GetID() .. "]"

	libTimer:NextFrame(self._CreateRemoveTimerName, function()
		if not IsValid(self) then return end
		if self._markedforremove then return end

		self.Created = true
		self:CallHook("Initialize")
	end)
end

function CLASS:Remove()
	if not self.Valid then
		return
	end

	if self._markedforremove then
		return
	end

	libTimer:NextFrame(self._CreateRemoveTimerName, function()
		if not self then return end

		table.Empty(self)

		self.Valid = false
		self.Created = false
		self._markedforremove = true
	end)

	self._markedforremove = true
	libMemory:PreventOverflow()

	self:CallHook("OnRemove")
	libMemory:PreventOverflow()
end

function CLASS:GetFunction(name)
	if isfunction(name) then
		return name
	end

	name = tostring(name or "")

	local func = self[name]
	if not isfunction(func) then
		return nil
	end

	return func
end

function CLASS:CallHook(name, ...)
	local func = self:GetFunction(name)
	if not func then
		return nil
	end

	return func(self, ...)
end

function CLASS:IsValid()
	return self.Valid or false
end

function CLASS:GetName()
	return self.Name or ""
end

function CLASS:SetName(name)
	name = libString:SanitizeName(name)

	self.Name = name
end

local function getTrace(level, maxcount)
	level = level or 2
	maxcount = maxcount or 0

	local trace = {}

	if level == 0 then
		return trace
	end

	while true do
		local index = #trace
		if maxcount > 0 and index > maxcount then break end

		local info = debug.getinfo( level, "Sln" )
		if not info then break end

		local data = {}
		data.what = info.what
		data.name = info.name
		data.isC = info.what == "C"

		if not data.isC then
			data.line = info.currentline
			data.file = info.short_src
		end

		trace[index + 1] = data
		level = level + 1
	end

	return trace
end

local color1 = Color(60, 200, 60);
local color2 = Color(120,200,120);
local color3 = Color(240,120,60);

function CLASS:Print(...)
	local trace = getTrace(3)
	local args = {...}

	MsgC(color1, tostring(self), ":\n")

	for k, info in pairs(trace) do
		local name = info.name and "\"" .. info.name .. "\"" or "(unknown)"

		if info.isC then
			MsgC(color2, string.format( " %2.0f: C function %-30s\n", k, name ) )
		else
			MsgC(color2, string.format( " %2.0f: %-30s %s:%i\n", k, name, info.file, info.line ) )
		end
	end

	Msg("\n")

	if #args == 1 and istable(args[1]) then
		args = args[1]
		local i = 1

		for k, v in pairs(args) do
			MsgC(color3, string.format( "#%02.0f:\n", i) )
			MsgC(color3, string.format( "  key   -> %10s:\t", i, type(k) ) )
			Msg(tostring(k), "\n")

			MsgC(color3, string.format( "  value -> %10s:\t", i, type(k) ) )
			Msg(tostring(v), "\n")
			Msg("\n")

			i = i + 1
		end

		return
	end

	for k, v in pairs(args) do
		MsgC(color3, string.format( "#%02.0f -> %10s:\t", k, type(v) ) )
		Msg(tostring(v), "\n")
	end

	Msg("\n\n")
end

CLASS.print = CLASS.Print

function CLASS:ToString()
	local r = "[" .. self.classname .. "]"

	if not self:IsValid() then
		return r .. "[Removed]"
	end

	r = r .. "[" .. self.ID .. "]"

	local name = self.Name or ""

	if name == "" then
		return r
	end

	r = r .. "[" .. name .. "]"
	return r
end

function CLASS:IsEqual(other)
	if not istable(other) then return false end
	if self.classname ~= other.classname then return false end

	return self:GetID() == other:GetID()
end

function CLASS:__tostring()
	local called = self._tostringcall
	if called then return "[" .. self.classname .. "][" .. self.ID .. "]" end

	self._tostringcall = true
	local r = self:ToString() or ""
	self._tostringcall = nil

	return r
end

function CLASS:__gc()
	self:Remove()
end

function CLASS:__eq(...)
	return self:IsEqual(...)
end

return CLASS
