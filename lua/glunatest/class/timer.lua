local libTimer = nil
local libString = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libTimer = classLib.LIB.timer
	libString = classLib.LIB.string
end

function CLASS:Create()
	BASE.Create(self)
end

function CLASS:Remove()
	BASE.Remove(self)
end

function CLASS:GetTimerName(identifier)
	local name = "OBJ[" .. self:GetClassname() .. "][" .. self:GetID() .. "]_" .. tostring(identifier or "")
	return name
end

function CLASS:Interval(identifier, delay, repetitions, func)
	if not self:IsValid() then
		return
	end

	local name = self:GetTimerName(identifier)

	libTimer:Remove(name)
	libTimer:Interval(name, delay, repetitions, function()
		if not IsValid(self) then
			libTimer:Remove(name)
			return
		end

		if self._markedforremove then
			libTimer:Remove(name)
			return
		end

		func = self:GetFunction(func)
		if not func then
			libTimer:Remove(name)
			return
		end

		func(self)
	end)
end

function CLASS:Once(identifier, delay, func)
	if not self:IsValid() then
		return
	end

	local name = self:GetTimerName(identifier)

	libTimer:Remove(name)
	libTimer:Once(name, delay, function()
		if not IsValid(self) then
			libTimer:Remove(name)
			return
		end

		if self._markedforremove then
			libTimer:Remove(name)
			return
		end

		func = self:GetFunction(func)
		if not func then return end

		func(self)
	end)
end

function CLASS:Util(identifier, delay, func)
	if not self:IsValid() then
		return
	end

	local name = self:GetTimerName(identifier)

	libTimer:Remove(name)
	libTimer:Util(name, delay, function()
		if not IsValid(self) then
			libTimer:Remove(name)
			return true
		end

		if self._markedforremove then
			libTimer:Remove(name)
			return true
		end

		func = self:GetFunction(func)
		if not func then
			return true
		end

		return func(self)
	end)
end

function CLASS:NextFrame(identifier, delay, func)
	if not self:IsValid() then
		return
	end

	local name = self:GetTimerName(identifier)

	libTimer:Remove(name)
	libTimer:NextFrame(name, delay, function()
		if not IsValid(self) then
			libTimer:Remove(name)
			return
		end

		if self._markedforremove then
			libTimer:Remove(name)
			return
		end

		func = self:GetFunction(func)
		if not func then
			return
		end

		return func(self)
	end)
end

function CLASS:TimerRemove(identifier)
	local name = self:GetTimerName(identifier)
	libTimer:Remove(name)
end

return CLASS
