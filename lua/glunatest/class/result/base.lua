local CLASS = {}
local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create(data)
	BASE.Create(self)

	if not istable(data) then
		data = {}
	end

	for k, v in pairs(data) do
		if not isstring(k) then
			continue
		end

		k = string.Trim(k)

		if k == "" then
			continue
		end

		if v == nil then
			continue
		end

		local varName = "_" .. string.lower(k)
		local getterName = "get" .. string.gsub(k, "^%l", string.upper)

		self[varName] = v

		if not isfunction(self[getterName]) then
			self[getterName] = function(this)
				return this[varName]
			end
		end
	end
end

return CLASS
