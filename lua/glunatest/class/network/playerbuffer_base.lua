local libNet = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "network/base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libNet = classLib.LIB.net
end

function CLASS:Create(handler, ply)
	BASE.Create(self)

	self.ply = ply
	self.packets = self:CreateObj("queue")
	self.timer = self:CreateObj("timer")
	self.handler = handler

	self:Clear()
end

function CLASS:Remove()
	self:Reset()
	self:StopTimeout()

	if self.packets then
		self.packets:Remove()
		self.packets = nil
	end

	if self.timer then
		self.timer:Remove()
		self.timer = nil
	end

	self.handler = nil
	self.ply = nil

	BASE.Remove(self)
end

function CLASS:IsValid()
	if not BASE.IsValid(self) then
		return false
	end

	if not IsValid(self.packets) then
		return false
	end

	if not IsValid(self.timer) then
		return false
	end

	return true
end

function CLASS:SetPlayer(ply)
	self.ply = ply
end

function CLASS:GetPlayer(ply)
	return self.ply
end

function CLASS:GetHandler()
	return self.handler
end

function CLASS:Push(data)
	self.packets:PushRight(data)
end

function CLASS:Pop()
	return self.packets:PopLeft()
end

function CLASS:Read()
	return self.packets:GetLeft()
end

function CLASS:GetSize()
	return self.packets:GetSize()
end

function CLASS:Clear()
	if not self:IsValid() then return end
	self.packets:Clear()
end

function CLASS:StopTimeout()
	if not self:IsValid() then return end

	self.timer:TimerRemove("Timeout")
	self.timer:TimerRemove("SendAlive")
end

function CLASS:ResetTimeout()
	if not self:IsValid() then return end

	local handler = self:GetHandler()
	local timeout = handler:GetTimeout()

	self:StopTimeout()

	if timeout <= 0 then
		return
	end

	self.timer:Interval("SendAlive", (timeout - 0.2) / 2, 5, function()
		local timeout = handler:GetTimeout()

		if timeout <= 0 then
			self:StopTimeout()
			return
		end

		self:SendAlive()
	end)

	self.timer:Once("Timeout", timeout, function()
		local timeout = handler:GetTimeout()

		if timeout <= 0 then
			self:StopTimeout()
			return
		end

		self:Timeout()
	end)
end

function CLASS:Timeout()
	if not self:IsValid() then return end

	local ply = self.ply

	self:CallHook("OnTimeout", ply)

	self.running = false
	self:Remove()
end

function CLASS:SendAlive()
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	return handler:CallHook("SendAlive", ply)
end

function CLASS:OnTimeout(ply)
	if not self:IsValid() then return end

	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	handler:CallHook("OnTimeout", ply)
	self:OnDone()
end

function CLASS:OnDone()
	if not self:IsValid() then return end
	if self.done then return end

	local ply = self.ply
	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	self.done = true
	handler:CallHook("OnDone", ply)
end

function CLASS:OnTransmitted()
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	handler:CallHook("OnTransmitted", ply)
	self:OnDone()
end

function CLASS:OnCancel()
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	handler:CallHook("OnCancel", ply)
	self:OnDone()
end

function CLASS:OnError(status)
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()
	local statusname = libNet:GetStatusName(status)

	if CLIENT then
		ply = nil
	end

	handler:CallHook("OnError", status, statusname, ply)
	self:OnDone()
end

function CLASS:OnProgress(data)
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	return handler:CallHook("OnProgress", data, ply)
end

function CLASS:OnReceive(datastream)
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()

	if CLIENT then
		ply = nil
	end

	handler:CallHook("OnReceive", datastream, ply)
	self:OnDone()
end

function CLASS:Reset()
	self.done = nil
end

function CLASS:ToString()
	local r = BASE.ToString(self)
	if not self:IsValid() then
		return r
	end

	local ply = self.ply

	if ply then
		r = r .. string.format("[ply: %s]", self.ply)
	end

	return r
end

return CLASS
