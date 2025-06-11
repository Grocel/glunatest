local CLASS = {}
local BASE = nil

CLASS.baseClassname = "object_manager/managed_base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create()
	BASE.Create(self)
end

return CLASS
