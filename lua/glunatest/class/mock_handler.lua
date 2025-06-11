local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create(mockLib, name)
	BASE.Create(self)

	self.lib = mockLib
	self:SetName(name)
	self:Clear()
end

function CLASS:Remove()
	local name = self:GetName()

	if self.lib and name ~= "" then
		self.lib:UnmockGlobalFunction(name)
	end

	self:Clear()
	self.lib = nil
	self:SetName(nil)

	BASE.Remove(self)
end

function CLASS:SetName(name)
	self.Name = tostring(name or "")
end

function CLASS:Reset()
	self.calledTimes = 0

	return self
end

function CLASS:Clear()
	self:Reset()
	self.callback = nil

	return self
end

function CLASS:GetCalled()
	assert(IsValid(self), "invalid mockHandler")

	return self.calledTimes or 0
end

function CLASS:WasNotCalled()
	assert(IsValid(self), "invalid mockHandler")

	return self:GetCalled() <= 0
end

function CLASS:WasCalled()
	assert(IsValid(self), "invalid mockHandler")

	return self:GetCalled() > 0
end

function CLASS:Callback(func)
	assert(IsValid(self), "invalid mockHandler")
	assert(isfunction(func), "bad argument #1, expected function")

	self.callback = func
end

function CLASS:IsValid()
	if not BASE.IsValid(self) then
		return false
	end

	if not self.lib then
		return false
	end

	return true
end

function CLASS:Handle(...)
	assert(IsValid(self), "invalid mockHandler")

	self.calledTimes = self.calledTimes + 1
	local callback = self.callback

	if callback then
		return callback(self, ...)
	end

	return nil
end

return CLASS
