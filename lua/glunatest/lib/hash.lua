local LIB = {}

local util_crc32 = util.CRC
local util_md5 = util.MD5
local util_sha256 = util.SHA256
local string_upper = string.upper

function LIB:SHA256_SUM(str)
	str = tostring(str or "")
	return string_upper(util_sha256(str))
end

function LIB:MD5_SUM(str)
	str = tostring(str or "")
	return string_upper(util_md5(str))
end

function LIB:CRC32_SUM(str)
	str = tostring(str or "")

	local hash = tonumber(util_crc32(str))
	hash = string.format("%08X", hash)

	return hash
end


return LIB
