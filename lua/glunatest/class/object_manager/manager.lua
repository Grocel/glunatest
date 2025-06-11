local CLASS = {}
local BASE = nil

CLASS.baseClassname = "object_manager/managed_base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create()
	BASE.Create(self)

	self.objs = {}
end

function CLASS:Remove()
	for k, v in pairs(self.objs) do
		if not IsValid(v) then
			continue
		end

		v:Remove()
	end

	self.objs = nil

	BASE.Remove(self)
end

function CLASS:DisattachObj(obj)
	if not self:IsValid() then
		return
	end

	if not IsValid(obj) then
		return
	end

	local name = obj:GetName()

	if self:Get(name) ~= obj then
		return
	end

	self:DisattachObjByName(name)
end

function CLASS:DisattachObjByName(name)
	if not self:IsValid() then
		return
	end

	local obj = self:Get(name)

	if not obj then
		self.objs[name] = nil
		return
	end

	obj:SetManager(nil)
	self.objs[name] = nil
end

function CLASS:AttachObj(obj, name)
	if not IsValid(obj) then
		return
	end

	name = tostring(name or "")

	if name == "" then
		name = tostring(obj:GetName() or "")
	end

	assert(name ~= "", "bad name of object to attach")

	obj:SetName(name)
	obj:SetManager(self)

	self.objs[name] = obj
	return self:Get(name)
end

function CLASS:IsValid()
	if not BASE.IsValid(self) then
		return false
	end

	if not self.objs then
		return false
	end

	return true
end

function CLASS:CleanUp()
	if not self:IsValid() then
		return
	end

	local cleanobjs = {}

	for k, v in pairs(self.objs) do
		local obj = self:Get(k)

		if not obj then
			continue
		end

		cleanobjs[k] = obj
	end

	self.objs = cleanobjs
end

function CLASS:CreateManagedObj(name, ...)
	if not self:IsValid() then
		return nil
	end

	name = tostring(name or "")
	local obj = self:Get(name)

	if obj then
		return obj
	end

	obj = self:CreateObj(...)
	return self:AttachObj(obj, name)
end

function CLASS:Get(name)
	if not self:IsValid() then
		return nil
	end

	name = tostring(name or "")
	local obj = self.objs[name]

	if not IsValid(obj) then
		return nil
	end

	if obj == self then
		return nil
	end

	if obj:GetManager() ~= self then
		return nil
	end

	if obj:GetName() ~= name then
		return nil
	end

	return obj
end

function CLASS:GetObjects()
	self:CleanUp()

	local objs = {}

	for k, v in pairs(self.objs) do
		objs[k] = v
	end

	return objs
end

return CLASS
