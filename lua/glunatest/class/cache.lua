local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create()
	BASE.Create(self)

	self._cache = {}
end

function CLASS:Remove()
	self._cache = nil

	BASE.Remove(self)
end

function CLASS:GetCacheValue(key)
	if not self._cache then
		return nil
	end

	return self._cache[tostring(key or "")]
end

function CLASS:GetCacheValues(key)
	local value = self:GetCacheValue(key)
	if not value then return nil end
	return unpack(value)
end

function CLASS:SetCacheValue(key, value)
	if not self._cache then
		return nil
	end

	self._cache[tostring(key or "")] = value
	return value
end

function CLASS:SetCacheValues(key, ...)
	local args = {...}
	self:SetCacheValue(key, args)
	return unpack(args)
end

function CLASS:DelCacheValue(key)
	if not self._cache then
		return nil
	end

	self._cache[tostring(key or "")] = nil
end

return CLASS
