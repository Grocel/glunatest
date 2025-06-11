local CLASS = {}
local libTable = nil
local libFile = nil

local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	libTable = classLib.LIB.table
	libFile = classLib.LIB.file

	BASE = self:GetBaseClass()
end

function CLASS:Create(virtualmount, virtualpath, defaultmount)
	BASE.Create(self)

	virtualmount = tostring(virtualmount or "")
	virtualpath = tostring(virtualpath or "")
	defaultmount = tostring(defaultmount or "")

	local realmount = virtualmount
	local realpath = virtualpath
	local resolvers = libFile:GetResolvers()

	for i, v in libTable:PrioritizedSortedPairs(resolvers, "priority") do
		local resolvedpath = nil
		local resolvedmount = nil

		if istable(v) and v.Resolve then
			resolvedpath, resolvedmount = v:Resolve(libFile, virtualmount, virtualpath)
		else
			resolvedpath, resolvedmount = v(libFile, virtualmount, virtualpath)
		end

		if resolvedpath == nil then
			continue
		end

		realmount = resolvedmount
		realpath = resolvedpath

		break
	end

	realmount = tostring(realmount or "")
	realpath = libFile:SanitizeFilename(realpath)

	if realmount == "" then
		realmount = defaultmount
	end

	self.realmount = realmount
	self.realpath = realpath
	self.virtualmount = virtualmount
	self.virtualpath = virtualpath
end

function CLASS:GetRealMount()
	return self.realmount
end

function CLASS:GetRealPath()
	return self.realpath
end

function CLASS:GetReal()
	return self.realpath, self.realmount
end

function CLASS:GetRealString()
	return string.format("%s:%s", self.realmount, self.realpath)
end

function CLASS:GetVirtualMount()
	return self.virtualmount
end

function CLASS:GetVirtualPath()
	return self.virtualpath
end

function CLASS:GetVirtual()
	return self.virtualpath, self.virtualmount
end

function CLASS:GetVirtualString()
	return string.format("%s:%s", self.virtualmount, self.virtualpath)
end

function CLASS:Concat(...)
	return libFile:Concat(self, ...)
end

function CLASS:ToString()
	local r = BASE.ToString(self)
	if not self:IsValid() then
		return r
	end

	local V, R = self:GetVirtualString(), self:GetRealString()

	if V == R then
		r = r .. string.format("[r-path: '%s']", R)
		return r
	end

	r = r .. string.format("[r-path: '%s'][v-path: '%s']", R, V)
	return r
end

function CLASS:__call()
	return self:GetReal()
end

function CLASS:__eq(other)
	if self:GetRealString() ~= other:GetRealString() then
		return false
	end

	return true
end

function CLASS:__concat(other)
	if istable(other) then
		error("can not concat two pathObjs", 2)
	end

	return self:Concat(other)
end

CLASS.__add = CLASS.__concat

return CLASS
