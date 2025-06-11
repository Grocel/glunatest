local CLASS = {}
local BASE = nil

CLASS.baseClassname = "result/base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create(data)
	BASE.Create(self, data)

	local syncobject = nil

	self.SetSyncObject = function(this, so)
		syncobject = so
		this.SetSyncObject = nil
	end

	self.GetSyncObject = function(this)
		return syncobject
	end
end

function CLASS:GetArgumentsAsTable()
	return self._arguments
end

function CLASS:GetArguments()
	return unpack(self._arguments)
end

function CLASS:GetReturnAsTable()
	return self._return
end

function CLASS:GetReturn()
	return unpack(self._return)
end

return CLASS
