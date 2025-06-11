local libString = nil
local libMemory = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libString = classLib.LIB.string
	libMemory = classLib.LIB.memory

	self.AddWriter = function(this, name, func, addTableFunc)
		name = tostring(name or "")
		name = string.gsub(name, "^%l", string.upper)

		local wfunc = function(that, value)
			func(that, value)
			return that
		end

		this["Write" .. name] = wfunc

		if not addTableFunc then
			return
		end

		this["Write" .. name .. "Table"] = function(that, tab)
			if not istable(tab) then
				tab = {tab}
			end

			local len = #tab
			len = math.Clamp(len, 0, 2 ^ 24 - 1)

			that:WriteUInt24(len)

			for i = 1, len do
				local value = tab[i]
				wfunc(that, value)
			end

			return that
		end
	end

	self.AddReader = function(this, name, func, addTableFunc)
		name = tostring(name or "")
		name = string.gsub(name, "^%l", string.upper)

		local rfunc = func

		this["Read" .. name] = rfunc

		if not addTableFunc then
			return
		end

		this["Read" .. name .. "Table"] = function(that)
			local len = that:ReadUInt24()

			if len <= 0 then
				return {}
			end

			local tab = {}

			for i = 1, len do
				local value = rfunc(that)
				tab[i] = value
			end

			return tab
		end
	end

	local ints = {
		8, 16, 24, 32, 48
	}

	for i, v in ipairs(ints) do
		local size = v / 8
		local maxint = 2 ^ v
		local max = maxint - 1

		local signedmaxint = 2 ^ (v - 1)
		local signedmax = signedmaxint - 1
		local signedmin = -signedmaxint

		self:AddWriter("UInt" .. v, function(this, value)
			value = tonumber(value or 0) or 0
			value = math.floor(value)
			value = math.Clamp(value, 0, max)

			local bytes = {}

			for offset = 1, size do
				local byte = value

				byte = math.floor(byte / (256 ^ (size - offset)))
				byte = bit.band(byte, 0xFF)

				bytes[offset] = byte
			end

			bytes = string.char(unpack(bytes))
			this:WriteRaw(bytes, size)
		end, true)

		self:AddReader("UInt" .. v, function(this)
			local rawdata = this:ReadRaw(size)

			if not rawdata then
				return 0
			end

			local value = 0
			for offset = 1, size do
				local byte = string.byte(rawdata, offset)
				value = value + byte * (256 ^ (size - offset))
			end

			value = math.Clamp(value, 0, max)

			return value
		end, true)

		self:AddWriter("Int" .. v, function(this, value)
			value = tonumber(value or 0) or 0
			value = math.floor(value)
			value = math.Clamp(value, signedmin, signedmax)

			if value < 0 then
				value = value + maxint
			end

			local bytes = {}

			for offset = 1, size do
				local byte = value

				byte = math.floor(byte / (256 ^ (size - offset)))
				byte = bit.band(byte, 0xFF)
				bytes[offset] = byte
			end

			bytes = string.char(unpack(bytes))
			this:WriteRaw(bytes, size)
		end, true)

		self:AddReader("Int" .. v, function(this)
			local rawdata = this:ReadRaw(size)

			if not rawdata then
				return 0
			end

			local value = 0
			for offset = 1, size do
				local byte = string.byte(rawdata, offset)
				value = value + byte * (256 ^ (size - offset))
			end

			if value >= signedmaxint then
				value = value - maxint
			end

			value = math.Clamp(value, signedmin, signedmax)

			return value
		end, true)
	end

	self:AddWriter("Bool", function(this, value)
		value = tobool(value) and 1 or 0
		this:WriteUInt8(value)
	end, true)

	self:AddReader("Bool", function(this)
		local value = this:ReadUInt8() >= 1
		return value
	end, true)

	self:AddWriter("Entity", function(this, value)
		if not IsValid(value) or not isentity(value) then
			value = 0
		else
			value = value:EntIndex()
		end

		this:WriteUInt16(value)
	end, true)

	self:AddReader("Entity", function(this)
		local value = this:ReadUInt16()

		value = Entity(value)
		return value
	end, true)

	self:AddWriter("String", function(this, value)
		value = tostring(value or "")

		local len = #value
		len = math.Clamp(len, 0, 2 ^ 24 - 1)

		this:WriteUInt24(len)
		this:WriteRaw(value, len)
	end, true)

	self:AddReader("String", function(this)
		local len = this:ReadUInt24()

		if len <= 0 then
			return ""
		end

		local value = this:ReadRaw(len)

		if not value then
			return ""
		end

		return value
	end, true)
end

function CLASS:Create(data, ashex)
	BASE.Create(self)

	if ashex then
		self:SetDataFromHex(data)
	else
		self:SetData(data)
	end
end

function CLASS:Remove()
	self:Clear()
	BASE.Remove(self)
end

function CLASS:Flush()
	if not self.rawDataIsDirty then
		return
	end

	libMemory:PreventOverflow()

	if self.data ~= "" then
		table.insert(self.rawData, 1, self.data)
	end

	self.data = table.concat(self.rawData)
	self.rawData = {}
	self.rawDataIsDirty = false

	libMemory:PreventOverflow()
end

function CLASS:Clear()
	self.data = ""
	self.rawData = {}
	self.rawDataIsDirty = true
	self:ResetReadPointer()

	self:Flush()
end

function CLASS:ResetReadPointer()
	self.readPointer = 0
end

function CLASS:GetReadPointer()
	return self.readPointer
end

function CLASS:SetReadPointer(p)
	p = tonumber(p or 0) or 0

	if p < 0 then
		p = 0
	end

	self.readPointer = p
end

function CLASS:MoveReadPointer(p)
	p = tonumber(p or 0) or 0

	self:SetReadPointer(self:GetReadPointer() + p)
end

function CLASS:ToString()
	self:Flush()
	return self.data
end

function CLASS:ToHex()
	local str = self:ToString()
	return libString:ToHex(str)
end

function CLASS:GetSize()
	self:Flush()
	return #self.data
end

function CLASS:SetData(str)
	str = tostring(str or "")
	self:Clear()

	self:AppendData(str)
end

function CLASS:SetDataFromHex(str)
	str = libString:FromHex(str)
	self:SetData(str)
end

function CLASS:AppendData(data)
	self.rawData[#self.rawData + 1] = tostring(data)
	self.rawDataIsDirty = true

	return self
end

function CLASS:WriteRaw(value, length)
	length = tonumber(length or 0) or 0
	value = tostring(value or "")
	value = string.sub(value, 1, length)

	self:AppendData(value)
	return self
end

function CLASS:ReadRaw(length)
	length = tonumber(length or 0) or 0
	local pointer = self.readPointer
	local nextPointer = pointer + length

	local value = self:ToString()
	local len = #value

	if len < nextPointer then
		return nil
	end

	value = string.sub(value, pointer + 1, nextPointer)
	libMemory:PreventOverflow()

	self.readPointer = nextPointer

	return value
end

function CLASS:IsEqual(other)
	return tostring(self) == tostring(other)
end

function CLASS:__add(other)
	self:AppendData(other)
	return self
end

CLASS.__concat = CLASS.__add

function CLASS:__lt(other, ...)
	return tostring(self) < tostring(other)
end

function CLASS:__le(other, ...)
	return tostring(self) > tostring(other)
end

return CLASS
