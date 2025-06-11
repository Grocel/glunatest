local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create(data)
	BASE.Create(self)

	self:Clear()

	if not istable(data) then
		data = {data}
	end

	for k, v in SortedPairs(data) do
		self:PushRight(v)
	end

	self:Normalize()
end

function CLASS:Remove()
	self:Clear()
	BASE.Remove(self)
end

function CLASS:PushLeft(value)
	if value == nil then
		return self
	end

	local count = self.count
	if count <= 0 then
		self.first = 1
		self.last = 0
	end

	local first = self.first - 1
	self.first = first
	self.list[first] = value

	self.count = self.count + 1
	self.canNormalize = true

	return self
end

function CLASS:PushRight(value)
	if value == nil then
		return self
	end

	local count = self.count
	if count <= 0 then
		self.first = 1
		self.last = 0
	end

	local last = self.last + 1
	self.last = last
	self.list[last] = value

	self.count = count + 1
	self.canNormalize = true

	return self
end

function CLASS:PopLeft()
	local first = self.first

	local value = self.list[first]
	if value == nil then
		return nil
	end

	self.list[first] = nil
	self.first = first + 1

	self.count = self.count - 1
	self.canNormalize = true

	return value
end

function CLASS:PopRight()
	local last = self.last

	local value = self.list[last]
	if value == nil then
		return nil
	end

	self[last] = nil
	self.last = last - 1

	self.count = self.count - 1
	self.canNormalize = true

	return value
end

function CLASS:GetLeft()
	local first = self.first

	local value = self.list[first]
	if value == nil then
		return nil
	end

	return value
end

function CLASS:GetRight()
	local last = self.last

	local value = self.list[last]
	if value == nil then
		return nil
	end

	return value
end

function CLASS:Clear()
	self.list = {}
	self.count = 0
	self.first = 1
	self.last = 0
	self.canNormalize = false
end

function CLASS:GetSize()
	return self.count
end

function CLASS:Normalize()
	if not self.canNormalize then
		return
	end

	local first = self.first
	local last = self.last
	local list = self.list

	self:Clear()

	for i = first, last, 1 do
		local value = list[i]
		if value == nil then
			continue
		end

		self:PushRight(value)
	end

	self.canNormalize = false
end

function CLASS:Reverse()
	local first = self.first
	local last = self.last
	local list = self.list

	self:Clear()

	for i = last, first, -1 do
		local value = list[i]
		if value == nil then
			continue
		end

		self:PushRight(value)
	end
end

function CLASS:ToTable()
	self:Normalize()
	return table.Copy(self.list)
end

function CLASS:ToString()
	local r = BASE.ToString(self)
	if not self:IsValid() then
		return r
	end

	r = r .. string.format("[count: %d][L: %d, R: %d]", self.count, self.first, self.last)
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
