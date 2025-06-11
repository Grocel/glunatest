local libString = nil
local libTable = nil

local LIB = {}

local cache = {}

function LIB:Load(lib)
	libString = lib.string
	libTable = lib.table
end

local function escape(str)
	return libString:PatternEscape(str)
end

local function unescape(str)
	return libString:PatternUnescape(str)
end

function LIB:InjectCode(code, pattern, injections)
	local cachekey = libTable:Hash(code) .. libTable:Hash(pattern) .. libTable:Hash(injections)

	if cache[cachekey] then
		return cache[cachekey]
	end

	cache[cachekey] = nil

	code = tostring(code or "")
	pattern = tostring(pattern or "")

	pattern = escape(pattern)
	pattern = "( " .. pattern .. " )"
	pattern = string.gsub(pattern, escape(escape("{{...}}")), escape(".+"))

	if not istable(injections) then
		injections = {
			inject = injections
		}
	end

	injections["/*"] = "--[["
	injections["*/"] = "]]--"

	injections["--[["] = "--[["
	injections["]]--"] = "]]--"

	local placeholders = {}

	local b1 = escape("{{")
	local b2 = escape("}}")

	local newpattern, count = string.gsub(pattern, escape(b1) .. ".-" .. escape(b2), function(match)
		placeholders[#placeholders + 1] = string.match(unescape(match), b1 .. "(.-)" .. b2) or ""

		return " ).-( "
	end)

	newpattern = string.gsub(newpattern,"[%s]+", escape("[%s]*"))

	if count <= 0 then
		return nil
	end

	if #placeholders <= 0 then
		return nil
	end

	local i = 0

	local newcode, count = string.gsub(code, newpattern, function(...)
		local codesegments = {...}
		local replacement = {}

		for _, v in ipairs(codesegments) do
			i = i + 1

			local injectionname = tostring(placeholders[i] or "")
			local injection = tostring(injections[injectionname] or "")

			injection = string.Trim(injection)

			if injection == "" then
				replacement[#replacement + 1] = v
				continue
			end

			replacement[#replacement + 1] = v
			replacement[#replacement + 1] = "\n"
			replacement[#replacement + 1] = injection
			replacement[#replacement + 1] = "\n"
		end

		if #replacement <= 0 then
			return nil
		end

		replacement = table.concat(replacement)
		return replacement
	end)

	if i <= 0 then
		return nil
	end

	if count <= 0 then
		return nil
	end

	cache[cachekey] = newcode
	return newcode
end

return LIB
