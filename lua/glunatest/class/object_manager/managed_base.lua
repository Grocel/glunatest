local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create()
	BASE.Create(self)

	self:SetManager(nil)
end

function CLASS:Remove()
	self:Disattach()

	BASE.Remove(self)
end

function CLASS:SetManager(manager)
	self.manager = manager
end

function CLASS:GetManager()
	return self.manager
end

function CLASS:Disattach()
	if not self:IsValid() then
		return
	end

	local manager = self:GetManager()
	manager:DisattachObj(self)
end

function CLASS:SetName(name)
	local oldName = tostring(self.Name or "")
	local name = tostring(name or "")

	self.Name = name

	if name == oldName then
		return
	end

	local manager = self:GetManager()

	if IsValid(manager) then
		manager:DisattachObjByName(name)
		manager:AttachObj(self, name)
	end

	self:CallHook("OnNameChange", name, oldName)
end

return CLASS
