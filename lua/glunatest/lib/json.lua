local libString = nil

local LIB = {}

function LIB:Load(lib)
	libString = lib.string
end

function LIB:Ready(lib)
	local libClass = lib.class

	local class = libClass:GetClass("stream")

	class:AddWriter("Json", function(this, value)
		value = self:Encode(value)

		this:WriteString(value)
	end)

	class:AddReader("Json", function(this)
		local value = this:ReadString()

		if value == "" then
			return nil
		end

		value = self:Decode(value)
		if not value then
			return nil
		end

		return value
	end)
end

function LIB:Encode(data, prettyPrint)
	if not istable(data) then
		data = {data}
	end

	local data = util.TableToJSON(data, prettyPrint)
	data = libString:NormalizeNewlines(data, "\n")

	return data
end

function LIB:Decode(data)
	data = tostring(data or "")
	data = libString:NormalizeNewlines(data, "\n")

	data = string.Trim(data)
	if data == "" then
		return {}
	end

	data = util.JSONToTable(data)
	if not data then
		return nil
	end

	if not istable(data) then
		data = {data}
	end

	return data
end


return LIB
