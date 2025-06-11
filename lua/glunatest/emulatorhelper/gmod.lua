if not GLUNATEST then
   return
end

local LIB = GLunaTestLib

local libString = LIB.string

local glunatest = GLUNATEST

local _fmt = string.format

local asserttypelist = {
	["boolean"] = {
		checkfunc = isbool,
	},

	["number"] = {
		checkfunc = isnumber,
	},

	["string"] = {
		checkfunc = isstring,
	},

	["function"] = {
		checkfunc = isfunction,
	},

	["table"] = {
		checkfunc = istable,
	},

	["vector"] = {
		checkfunc = isvector,
	},

	["angle"] = {
		checkfunc = isangle,
	},

	["matrix"] = {
		checkfunc = ismatrix,
	},

	["entity"] = {
		checkfunc = isentity,
	},

	["panel"] = {
		checkfunc = ispanel or (function()
			return false
		end),
	},
}

for typename, v in pairs(asserttypelist) do
	local checkfunc = v.checkfunc
	local notcheckfunc = v.notcheckfunc

	glunatest.add_type_assertion_function(typename, checkfunc, notcheckfunc)
end

local function saveIsValid(val)
	local status, err = pcall(IsValid, val)

	if not status then
		return false
	end

	return err or false
end

local function saveIsNotValid(val)
	return not saveIsValid(val)
end

glunatest.add_assertion_function("valid", saveIsValid, function(val)
	return {
		reason = _fmt("Expected valid object, got %s (type: %s)", libString:LimitString(tostring(val), 30), type(val))
	}
end)

glunatest.add_assertion_function("not_valid", saveIsNotValid, function(val)
	return {
		reason = _fmt("Expected valid object, got %s (type: %s)", libString:LimitString(tostring(val), 30), type(val))
	}
end)

function glunatest.getPlayer()
	local ply = glunatest.PLAYER

	-- get player that startet the test
	if IsValid(ply) and ply:IsPlayer() then
		glunatest.PLAYER = ply
		return ply
	end

	if CLIENT then
		-- get local player
		ply = LocalPlayer()

		if IsValid(ply) then
			glunatest.PLAYER = ply
			return ply
		end

		return nil
	end

	local plys = player.GetHumans()

	-- get first superadmin player
	for i, v in ipairs(plys) do
		if not IsValid(v) then
			continue
		end

		if not v:IsSuperAdmin() then
			continue
		end

		glunatest.PLAYER = v
		return v
	end

	-- get first admin player
	for i, v in ipairs(plys) do
		if not IsValid(v) then
			continue
		end

		if not v:IsAdmin() then
			continue
		end

		glunatest.PLAYER = v
		return v
	end

	-- get first player
	for i, v in ipairs(plys) do
		if not IsValid(v) then
			continue
		end

		glunatest.PLAYER = v
		return v
	end

	return nil
end

GLUNATEST = glunatest
