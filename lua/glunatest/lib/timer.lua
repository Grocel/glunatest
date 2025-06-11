local libString = nil
local libLIB = nil

local LIB = {}

LIB.TIME_NEXTFRAME = 0.0001

function LIB:Load(lib)
	libString = lib.string
	libLIB = lib
end

local function getName(identifier)
	identifier = libString:SanitizeName(identifier)

	local name = libLIB:GetName()
	local timername = name .. "_timer_" .. identifier

	return timername
end

function LIB:Interval(identifier, delay, repetitions, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	timer.Remove(name)
	timer.Create(name, delay, repetitions, func)
end

function LIB:Once(identifier, delay, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	timer.Remove(name)
	timer.Create(name, delay, 1, function()
		timer.Remove(name)
		func()
	end)
end

function LIB:Util(identifier, delay, func)
	if not isfunction(func) then return end
	local name = getName(identifier)

	timer.Remove(name)
	timer.Create(name, delay, 0, function()
		local endtimer = func()
		if not endtimer then return end

		timer.Remove(name)
	end)
end

function LIB:NextFrame(identifier, func)
	self:Once(identifier, self.TIME_NEXTFRAME, func)
end

function LIB:Remove(identifier)
	local name = getName(identifier)
	timer.Remove(name)
end

return LIB
