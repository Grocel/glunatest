local libNet = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "object_manager/manager"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libNet = classLib.LIB.net
end

function CLASS:Create()
	BASE.Create(self)
end

function CLASS:Remove()
	BASE.Remove(self)
end

function CLASS:StopTimeout(ply)
	if not self:IsValid() then return end

	local handlers = self:GetObjects()

	for k, handler in pairs(handlers) do
		handler:StopTimeout(ply)
	end
end

function CLASS:ResetTimeout(ply)
	if not self:IsValid() then return end

	local handlers = self:GetObjects()

	for k, handler in pairs(handlers) do
		handler:ResetTimeout(ply)
	end
end

function CLASS:SendAlive(ply)
	if not self:IsValid() then return end

	libNet:SendAlive(ply)
end

return CLASS
