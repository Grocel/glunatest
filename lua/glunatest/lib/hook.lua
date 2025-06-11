local libString = nil
local libPrint = nil
local libLIB = nil

local g_HOOK = nil

local LIB = {}

function LIB:Load(lib)
	libString = lib.string
	libPrint = lib.print
	libLIB = lib
end

function LIB:Unload(lib)
	if g_HOOK then
		for eventname, hooks in pairs(g_HOOK) do
			for identifier, callback in pairs(hooks) do
				self:Remove(eventname, identifier)
			end
		end
	end

	g_HOOK = nil
end

local function getName(identifier)
	identifier = libString:SanitizeName(identifier)

	local name = libLIB:GetName()
	local hookname = name .. "_hook_" .. identifier

	return hookname
end

function LIB:Add(eventname, identifier, callback)
	assert(isfunction(callback), "bad argument #3, expected function")

	eventname = tostring(eventname or "")
	identifier = getName(identifier)

	g_HOOK = g_HOOK or {}
	g_HOOK[eventname] = g_HOOK[eventname] or {}

	if not g_HOOK[eventname][identifier] then
		g_HOOK[eventname][identifier] = callback

		hook.Add(eventname, identifier, function(...)
			if not istable(g_HOOK) then
				hook.Remove(eventname, identifier)
				libPrint:errorf("callback '%s' for event '%s' is invalid!", 1, identifier, eventname)
			end

			local funcs = g_HOOK[eventname]

			if not istable(funcs) then
				hook.Remove(eventname, identifier)
				libPrint:errorf("callback '%s' for event '%s' is invalid!", 1, identifier, eventname)
			end

			local func = funcs[identifier]

			if not isfunction(func) then
				hook.Remove(eventname, identifier)
				libPrint:errorf("callback '%s' for event '%s' is invalid!", 1, identifier, eventname)
			end

			return func(...)
		end)

		return
	end

	g_HOOK[eventname][identifier] = callback
end

function LIB:AddIgnorePauseThink(identifier, callback)
	identifier = tostring(identifier or "")

	if CLIENT then
		-- Doesn't get paused in single player. Can be important for vguis.
		self:Add("PostRenderVGUI", "ignorepausethink_" .. identifier, callback)
	else
		-- Servers still uses Think.
		self:Add("Think", "ignorepausethink_" .. identifier, callback)
	end
end

function LIB:Remove(eventname, identifier)
	eventname = tostring(eventname or "")
	identifier = getName(identifier)

	hook.Remove(eventname, identifier)

	g_HOOK = g_HOOK or {}
	g_HOOK[eventname] = g_HOOK[eventname] or {}
	g_HOOK[eventname][identifier] = nil
end

return LIB
