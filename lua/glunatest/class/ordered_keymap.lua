local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create(data)
	BASE.Create(self)

	self.queueKey = self:CreateObj("queue")
	self.map = {}

	self:Clear()

	if not istable(data) then
		data = {data}
	end

	if data[1] and data[1].key then
		for i, kv in ipairs(data) do
			if kv.key == nil then
				continue
			end

			if kv.value == nil then
				continue
			end

			self:PushRight(kv.key, kv.value)
		end
	else
		for k, v in SortedPairs(data) do
			self:PushRight(k, v)
		end
	end

	self:Normalize()
end

function CLASS:Remove()
	self:Clear()

	if self.queue then
		self.queue:Remove()
		self.queue = nil
	end

	BASE.Remove(self)
end

function CLASS:PushLeft(key, value)
	if key == nil then
		return self
	end

	if value == nil then
		return self
	end

	if self.map[key] ~= nil then
		return self
	end

	self.queueKey:PushLeft(key)
	self.map[key] = value

	return self
end

function CLASS:PushRight(key, value)
	if key == nil then
		return self
	end

	if value == nil then
		return self
	end

	if self.map[key] ~= nil then
		return self
	end

	self.queueKey:PushRight(key)
	self.map[key] = value

	return self
end

function CLASS:Get(key)
	if key == nil then
		return nil
	end

	return self.map[key]
end

function CLASS:Set(key, value)
	if key == nil then
		return self
	end

	if value == nil then
		return self
	end

	self:PushRight(key, value)
	self.map[key] = value

	return self
end

function CLASS:PopLeft()
	local key = self.queueKey:PopLeft()

	if key == nil then
		return nil, nil
	end

	local value = self.map[key]
	self.map[key] = nil

	if value == nil then
		return nil, nil
	end

	return key, value
end

function CLASS:PopRight()
	local key = self.queueKey:PopRight()

	if key == nil then
		return nil, nil
	end

	local value = self.map[key]
	self.map[key] = nil

	if value == nil then
		return nil, nil
	end

	return key, value
end

function CLASS:GetLeft()
	local key = self.queueKey:GetLeft()

	if key == nil then
		return nil, nil
	end

	local value = self.map[key]

	if value == nil then
		return nil, nil
	end

	return key, value
end

function CLASS:GetRight()
	local key = self.queueKey:GetRight()

	if key == nil then
		return nil, nil
	end

	local value = self.map[key]

	if value == nil then
		return nil, nil
	end

	return key, value
end

function CLASS:Clear()
	self.queueKey:Clear()

	self.map = {}
end

function CLASS:GetSize()
	return self.queueKey:GetSize()
end

function CLASS:Normalize()
	self.queueKey:Normalize()
end

function CLASS:Reverse()
	self.queueKey:Reverse()
end

function CLASS:ToTable()
	local keys = self.queueKey:ToTable()
	local tab = {}

	for i, key in ipairs(keys) do
		local value = self:Get(key)
		if value == nil then
			continue
		end

		tab[#tab + 1] = {
			key = key,
			value = value,
		}
	end

	return tab
end

function CLASS:ToString()
	local r = BASE.ToString(self)
	if not self:IsValid() then
		return r
	end

	r = r .. string.format("[count: %d]", self:GetSize())
	return r
end

function CLASS:Copy()
	return self:CreateObj(self.classname, self:ToTable())
end

function CLASS:__sub(other)
	self:PushLeft(other)
	return self
end

function CLASS:__add(other)
	self:PushRight(other)
	return self
end

CLASS.__concat = CLASS.__add

return CLASS
