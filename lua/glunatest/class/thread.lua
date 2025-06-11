local CLASS = {}
local libCoroutine = nil

local coroutine = coroutine
local coroutine_running = coroutine.running
local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status
local coroutine_create = coroutine.create
local coroutine_yield = coroutine.yield

local IsValid = IsValid
local ipairs = ipairs
local pairs = pairs

local istable = istable
local isstring = isstring
local isfunction = isfunction
local tostring = tostring
local tonumber = tonumber

local xpcall = xpcall

local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()

	libCoroutine = classLib.LIB.coroutine
end

function CLASS:Create(func, parent, callbackOnExit)
	assert(isfunction(func), "bad argument #1, expected function")

	BASE.Create(self)

	local co = coroutine_create(func)

	if parent then
		parent = self:GetThread(parent)
	end

	self.coroutine = co
	self.coroutineId = tostring(co)
	self.parent = parent
	self.children = {}
	self.childrenIndex = {}
	self.callback = callbackOnExit
	self.skipyields = false
end

function CLASS:Remove()
	local id = self.coroutineId
	local parent = self.parent
	local callback = self.callback
	local children = self.children

	if callback then
		self.callback = nil
		callback(self)
	end

	for k, v in pairs(self) do
		if isfunction(v) then
			continue
		end

		self[k] = nil
	end

	if parent then
		parent.childrencached = nil
	end

	if children then
		for i, v in ipairs(children) do
			if not IsValid(v) then
				continue
			end

			v.childrencached = nil
			v:Remove()
		end
	end

	BASE.Remove(self)
end

function CLASS:IsValid()
	if not BASE.IsValid(self) then
		return false
	end

	if not self.coroutine then
		return false
	end

	if not self.coroutineId then
		return false
	end

	return true
end

function CLASS:GetCoroutine()
	if not self:IsValid() then
		return nil
	end

	return self.coroutine
end

function CLASS:GetCoroutineId()
	if not self:IsValid() then
		return nil
	end

	return self.coroutineId
end

function CLASS:Resume()
	if not self:IsValid() then
		return nil
	end

	local co = self.coroutine

	if coroutine_status(co) == "dead" then
		self:Remove()
		return nil
	end

	local resumestatus = false
	local resumeerr = nil
	local time = nil

	xpcall(function()
		local status, err = coroutine_resume(co)

		if not status then
			if err and err ~= "" then
				error(err)
			end

			return
		end

		resumestatus = status
		time = tonumber(err or 0) or 0
	end, function(thiserr)
		resumestatus = false
		resumeerr = thiserr
		time = nil
	end)

	if not resumestatus then
		self:Remove()

		if resumeerr and resumeerr ~= "" then
			error(resumeerr)
		end

		return nil
	end

	if not time or time <= 0 then
		time = nil
	end

	return time
end

function CLASS:AddChild(child)
	if not self:IsValid() then
		return nil
	end

	child = self:GetThread(child)
	if not IsValid(child) then
		return nil
	end

	local parent = self:GetThread(child.parent)

	self.children = self.children or {}
	self.childrenIndex = self.childrenIndex or {}

	if parent ~= self then
		if IsValid(parent) then
			parent.childrenIndex = self.childrenIndex or {}
			parent.childrenIndex[child.coroutineId] = nil
			parent.childrencached = nil
		end

		child.parent = self
		child.childrencached = nil

		self.childrencached = nil
	end

	if self.childrenIndex[child.coroutineId] then
		return self.childrenIndex[child.coroutineId]
	end

	self.children[#self.children + 1] = child
	self.childrenIndex[child.coroutineId] = #self.children
	self.childrencached = nil
	child.childrencached = nil

	return child
end

function CLASS:GetChildren()
	if not self:IsValid() then
		return nil
	end

	if self.childrencached then
		return self.children
	end

	local children = {}
	self.childrenIndex = {}

	for k, child in ipairs(self.children or {}) do
		if not IsValid(child) then
			continue
		end

		if child.parent ~= self then
			continue
		end

		if self.childrenIndex[child.coroutineId] then
			continue
		end

		children[#children + 1] = child
		self.childrenIndex[child.coroutineId] = child
	end

	self.children = children
	self.childrencached = true

	return self.children
end

function CLASS:GetFirstChild()
	local children = self:GetChildren()
	local firstchild = children[1]

	if not IsValid(firstchild) then
		self.childrencached = nil
	end

	children = self:GetChildren()
	firstchild = children[1]

	if not IsValid(firstchild) then
		return nil
	end

	return firstchild
end

function CLASS:GetInnermostFirstChild()
	local firstchild = self:GetFirstChild()

	if not IsValid(firstchild) then
		return nil
	end

	while true do
		local child = firstchild:GetFirstChild()

		if not IsValid(child) then
			return firstchild
		end

		firstchild = child
	end

	return nil
end

function CLASS:IsSkippingYields()
	return self.skipyields or false
end

function CLASS:SetSkippingYields(value)
	self.skipyields = value or false
	return true
end

function CLASS:Yield(time)
	if not self:IsValid() then
		return false
	end

	if self.skipyields then
		return false
	end

	local curco = coroutine_running()

	if not curco then
		return false
	end

	if curco ~= self.coroutine then
		return false
	end

	time = tonumber(time or 0) or 0

	local suggess = false

	xpcall(function()
		coroutine_yield(time)
		suggess = true
	end, function(thiserr)
		suggess = false
	end)

	if not suggess then
		return false
	end

	return true
end

function CLASS:Exit()
	local curco = coroutine_running()

	if self.skipyields then
		return false
	end

	if not curco then
		return false
	end

	if curco ~= self.coroutine then
		return false
	end

	self:Remove()

	local suggess = false

	xpcall(function()
		coroutine_yield(0)
		suggess = true
	end, function(thiserr)
		suggess = false
	end)

	return suggess
end

function CLASS:GetThread(...)
	return libCoroutine:GetThread(...)
end

function CLASS:ToString()
	local r = BASE.ToString(self)
	if not self:IsValid() then
		return r
	end

	r = r .. string.format("[%s]", self.coroutineId)
	return r
end

function CLASS:__call()
	return self:Resume()
end

function CLASS:__add(other)
	self:AddChild(other)
	return self
end

return CLASS
