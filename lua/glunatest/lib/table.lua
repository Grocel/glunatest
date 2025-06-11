local libString = nil
local libCoroutine = nil
local libHash = nil

local tostring = tostring
local tonumber = tonumber

local isbool = isbool
local istable = istable
local isstring = isstring
local isvector = isvector
local isangle = isangle

local type = type
local getmetatable = getmetatable
local setmetatable = setmetatable

local pairs = pairs
local ipairs = ipairs

local Angle = Angle
local Vector = Vector

local string = string
local table = table

local string_format = string.format
local string_gsub = string.gsub
local string_trim = string.Trim
local string_rep = string.rep

local table_insert = table.insert
local table_sort = table.sort
local table_concat = table.concat
local table_upper = string.upper

local LIB = {}

function LIB:Load(lib)
	libString = lib.string
	libCoroutine = lib.coroutine
	libHash = lib.hash
end

local function valuetostring(V)
	if istable(V) then
		return nil
	end

	if isvector(V) then
		return string_format("Vector(%f, %f, %f)", V.x, V.y, V.z)
	end

	if isangle(V) then
		return string_format("Angle(%f, %f, %f)", V.pitch, V.yaw, V.roll)
	end

	local out = tostring(V)

	if isstring(V) then
		return string_format("\"%s\"", out)
	end

	return out
end

local allowedTypes = {
	["string"] = true,
	["number"] = true,
}

local function isDESC(aValue, bValue)
	if aValue == bValue then
		return nil
	end

	if aValue == false and bValue == nil then
		return true
	end

	if aValue == nil and bValue == false then
		return false
	end

	if aValue == true and bValue == nil then
		return true
	end

	if aValue == nil and bValue == true then
		return false
	end

	if aValue == true and bValue == false then
		return true
	end

	if aValue == false and bValue == true then
		return false
	end

	local isboolA = isbool(aValue)
	local isboolB = isbool(bValue)

	if not isboolA and bValue == nil then
		return true
	end

	if not isboolB and aValue == nil then
		return false
	end

	if not isboolA and isboolB then
		return true
	end

	if not isboolB and isboolA then
		return false
	end

	local typeA = type(aValue)
	local typeB = type(bValue)

	if typeA > typeB then
		return true
	end

	if typeA < typeB then
		return false
	end

	if not allowedTypes[typeA] or not allowedTypes[typeB] then
		aValue = tostring(aValue)
		bValue = tostring(bValue)
	end

	if aValue > bValue then
		return true
	end

	if aValue < bValue then
		return false
	end

	return nil
end

function LIB:sortByValues(t, ...)
	local valueKeys = {}

	for i, valueKey in ipairs({...}) do
		local name = valueKey
		local desc = false

		if istable(valueKey) then
			name = valueKey.name or valueKey[1]
			desc = valueKey.desc or valueKey[2] or false
		end

		valueKeys[#valueKeys + 1] = {
			name = name,
			desc = desc,
		}
	end

	table_sort(t, function (a, b)
		for i, valueKey in ipairs(valueKeys) do
			local name = valueKey.name
			local desc = valueKey.desc
			local aValue = a[name]
			local bValue = b[name]

			local sort = isDESC(aValue, bValue)

			if sort == nil then
				continue
			end

			if not desc then
				sort = not sort
			end

			return sort
		end
	end)

	return t
end

function LIB:Hash(var, cache)
	local varType = type(var)

	if not istable(var) then
		var = {var}
	end

	libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

	local salt = "TSKJRLMXQYPHVIZUN"

	local makehash = nil
	local sortedToHash = nil

	local done = {}

	cache = cache or {}

	local subHashes = {}

	dataMapToHash = function(dataMap)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		dataMap = self:sortByValues(dataMap, {
			"key", true
		}, {
			"value", true
		})

		local tmp = {}
		local X = 0
		local Y = 0

		X = X + 1
		X = X % #salt
		Y = Y + 3
		Y = Y % #salt

		for i, v in ipairs(dataMap) do
			local h = {}

			h[#h + 1] = tostring(v.key or "")
			h[#h + 1] =	tostring(v.value or "")
			h[#h + 1] = i

			h = table_concat(h)

			tmp[#tmp + 1] = X
			tmp[#tmp + 1] = Y
			tmp[#tmp + 1] = h
			tmp[#tmp + 1] = #h

			X = X + 1
			X = X % #salt
			Y = Y + 2
			Y = Y % #salt
		end

		tmp = table_concat(tmp)

		X = X + 1
		X = X % #salt
		Y = Y + 1
		Y = Y % #salt

		local HX = salt[X + 1]
		local HY = salt[Y + 1]

		local hash = {}
		hash[#hash + 1] = HX
		hash[#hash + 1] = HY
		hash[#hash + 1] = table_upper(libHash:MD5_SUM(table_concat({salt, tmp, X, #tmp, HY, varType})))
		hash[#hash + 1] = table_upper(libHash:MD5_SUM(table_concat({salt, tmp, Y, #tmp, HX, varType})))

		hash = table_concat(hash)
		return hash
	end

	makehash = function(T)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		if not istable(T) then
			return nil
		end

		if cache[T] then
			return cache[T]
		end

		if done[T] then
			return nil
		end

		done[T] = true

		local dataMap = {}

		for k, v in pairs(T) do
			local value = valuetostring(v)
			local key = valuetostring(k)

			local valuen = tonumber(value)
			local keyn = tonumber(key)

			if valuen ~= nil then
				value = valuen
			end

			if keyn ~= nil then
				key = keyn
			end

			local subHash = {}

			if istable(v) then
				value = makehash(v)
			end

			if istable(k) then
				key = makehash(k)
			end

			local dataValue = {}

			dataValue.value = value
			dataValue.key = key

			if dataValue.value or dataValue.key then
				dataMap[#dataMap + 1] = dataValue
			end
		end

		local hash = dataMapToHash(dataMap)

		cache[T] = hash

		return hash
	end

	return makehash(var)
end


function LIB:ToString(var, replaceWhiteSpace)
	if not istable(var) then
		return tostring(var)
	end

	libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

	if replaceWhiteSpace == nil then
		replaceWhiteSpace = true
	end

	local tab = "\t"
	local nl = "\n"

	local makemap = nil
	local makestring = nil
	local makeiterationmap = nil

	local mapDone = {}
	local mapDoneLoop = {}
	local mapKeyTables = {}
	local mapKeyTablesLoop = {}
	local hashCache = {}

	makemap = function(T, lastpath)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		if not istable(T) then
			return
		end

		lastpath = lastpath or ""

		if mapDone[T] then
			mapDoneLoop[T] = mapDone[T]
			return
		end

		mapDone[T] = lastpath
		local keytables = {}

		for k, v in pairs(T) do
			local kname = valuetostring(k)
			if not kname then
				kname = mapKeyTables[k]

				if not kname then
					local id = self:Hash(k, hashCache)
					kname = string_format("Key table %s", id)

					mapKeyTables[k] = kname
					keytables[k] = kname
				else
					mapKeyTablesLoop[k] = kname
				end
			end

			local nextpath = string_format("%s[%s]", lastpath, kname)
			makemap(v, nextpath)
		end

		for k, v in pairs(keytables) do
			makemap(k, v)
		end
	end

	makemap(var, "self")

	local makeinterationmap
	local interationDone = {}

	makeinterationmap = function(T, level)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		level = level or 0

		if not istable(T) then
			return nil
		end

		if interationDone[T] then
			return interationDone[T]
		end

		local interationMap = {}
		interationDone[T] = interationMap

		for k, v in pairs(T) do
			local sortKey = k
			local sortValue = v

			local istableKey = istable(k)
			local istableValue = istable(v)

			if istableKey then
				sortKey = self:Hash(k, hashCache)
			end

			if istableValue then
				sortValue = self:Hash(v, hashCache)
			end

			interationMap[#interationMap + 1] = {
				istableKey = istableKey,
				istableValue = istableValue,
				key = sortKey,
				value = sortValue,
				k = k,
				v = v,
				level = level,
				interationMapKey = makeinterationmap(k, level + 1),
				interationMapValue = makeinterationmap(v, level + 1),
			}
		end

		interationMap = self:sortByValues(interationMap, "istableKey", "key", "istableValue", "value")

		return interationMap
	end

	local interationMap = makeinterationmap(var)

	local mapDone = {}
	local mapNamesValues = {}
	local mapNamesKeys = {}

	makestring = function(IMap, level, name)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		level = level or 0

		if not istable(IMap) then
			return nil
		end

		if mapDone[IMap] then
			return nil
		end

		mapDone[IMap] = true

		local buffer = {}
		local indent = string_rep(tab, level)
		local currentindent = indent .. tab

		buffer[#buffer + 1] = "{"

		if name then
			buffer[#buffer + 1] = nl
			buffer[#buffer + 1] = currentindent
			buffer[#buffer + 1] = "/* "
			buffer[#buffer + 1] = name
			buffer[#buffer + 1] = " */"
		end

		buffer[#buffer + 1] = nl

		local vB = {}

		for i, I in ipairs(IMap) do
			local k = I.k
			local v = I.v

			local vKeyTableName = mapKeyTablesLoop[v]
			local vLoopTableName = mapDoneLoop[v]
			local shortValue = mapNamesValues[I]

			if not shortValue then
				if vLoopTableName then
					shortValue = vLoopTableName
				else
					if vKeyTableName then
						shortValue = vKeyTableName
					end
				end

				if shortValue then
					mapNamesValues[I] = shortValue
				end
			end

			local kKeyTableName = mapKeyTablesLoop[k]
			local kLoopTableName = mapDoneLoop[k]
			local shortKey = mapNamesKeys[I]

			if not shortKey then
				if kLoopTableName then
					shortKey = kLoopTableName
				else
					if kKeyTableName then
						shortKey = kKeyTableName
					end
				end

				if shortKey then
					mapNamesKeys[I] = shortKey
				end
			end

			local kstring = valuetostring(I.k)
			local vstring = valuetostring(I.v)

			local ktstring = makestring(I.interationMapKey, level + 2, shortKey)
			local vtstring = makestring(I.interationMapValue, level + 1, shortValue)

			local pB = {}
			pB[#pB + 1] = currentindent
			pB[#pB + 1] = "["

			if kstring then
				if replaceWhiteSpace and isstring(k) then
					kstring = libString:ReplaceWhiteSpace(kstring, false, false)
				end

				pB[#pB + 1] = kstring
			elseif ktstring then
				pB[#pB + 1] = nl
				pB[#pB + 1] = currentindent
				pB[#pB + 1] = tab

				pB[#pB + 1] = ktstring

				pB[#pB + 1] = nl
				pB[#pB + 1] = currentindent
			elseif shortKey then
				pB[#pB + 1] = shortKey
			end

			pB[#pB + 1] = "]"

			pB[#pB + 1] = " = "

			if vstring then
				if replaceWhiteSpace and isstring(v) then
					vstring = libString:ReplaceWhiteSpace(vstring, false, false)
				end

				pB[#pB + 1] = vstring
			elseif vtstring then
				pB[#pB + 1] = vtstring
			elseif shortValue then
				pB[#pB + 1] = shortValue
			end

			vB[#vB + 1] = table_concat(pB)
		end

		buffer[#buffer + 1] = table_concat(vB, "," .. nl)
		buffer[#buffer + 1] = nl
		buffer[#buffer + 1] = indent
		buffer[#buffer + 1] = "}"

		return table_concat(buffer)
	end

	return makestring(interationMap, 0, mapDoneLoop[var])
end

function LIB:Compare(tA, tB)
	local isequal

	local done = {}

	isequal = function(A, B)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		if tA == tB then
			return true
		end

		if not istable(A) then
			return (A == B)
		end

		if not istable(B) then
			return (A == B)
		end

		if TypeID(A) ~= TypeID(B) then
			return false
		end

		if type(A) ~= type(B) then
			return false
		end

		if tostring(A) == tostring(B) then
			return true
		end

		done[A] = done[A] or {}
		done[B] = done[B] or {}

		if done[A][B] then
			return nil
		end

		if done[B][A] then
			return nil
		end

		done[A][B] = true
		done[B][A] = true

		local keyTables = {}
		local keyTablesValuesA = {}
		local keyTablesValuesB = {}

		for k, v in pairs(A) do
			if istable(k) then
				keyTables[k] = true
				keyTablesValuesA[#keyTablesValuesA + 1] = {k, v}
				continue
			end

			local eq = isequal(A[k], B[k])

			if eq == nil then
				continue
			end

			if not eq then
				return false
			end
		end

		for k, v in pairs(B) do
			if istable(k) then
				keyTables[k] = true
				keyTablesValuesB[k] = v
				keyTablesValuesB[#keyTablesValuesB + 1] = {k, v}
				continue
			end

			if A[k] == nil then
				return false
			end
		end

		for i1, T1 in ipairs(keyTablesValuesA) do
			for i2, T2 in ipairs(keyTablesValuesB) do
				local k1 = T1[1]
				local k2 = T2[1]
				local A = T1[2]
				local B = T2[2]

				local eq = isequal(k1, k2)

				if eq == false then
					continue
				end

				eq = isequal(A, B)

				if eq == false then
					continue
				end

				keyTables[k1] = nil
				keyTables[k2] = nil
			end
		end

		for k, v in pairs(keyTables) do
			if not v then
				continue
			end

			return false
		end

		return true
	end

	return isequal(tA, tB)
end

function LIB:NaturalSortedPairs(tab, sort)
	local iterator = function(state)
		state.i = state.i + 1

		local kv = state.sorted[state.i]
		if kv == nil then
			return
		end

		return kv.k, kv.v
	end

	if sort == nil then
		sort = true
	end

	local sorted = {}

	for k, v in pairs(tab) do
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		local order = nil

		if sort then
			order = libString:SanitizeFunctionName(k)
			order = string_gsub(order, "[%_]?[%s]*[%d]+[%s]*$", function(number)
				number = string_trim(number)
				number = string_trim(number, "_")
				number = string_trim(number)
				number = tonumber(number)

				return string_format("_%011d", number)
			end)
		end

		sorted[#sorted + 1] = {
			k = k,
			v = v,
			order = order,
		}
	end

	if sort then
		table_sort(sorted, function(a, b)
			return a.order < b.order
		end)
	end

	return iterator, {
		i = 0,
		sorted = sorted,
	}
end

function LIB:PrioritizedSortedPairs(tab, prioritykey)
	prioritykey = tostring(prioritykey or "")

	if prioritykey == "" then
		prioritykey = "priority"
	end

	local iterator = function(state)
		state.i = state.i + 1

		local kv = state.sorted[state.i]
		if kv == nil then
			return
		end

		return kv.k, kv.v
	end

	local sorted = {}

	for k, v in pairs(tab) do
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		local priority = 0

		if istable(v) then
			priority = tonumber(v[prioritykey] or 0) or 0
		end

		sorted[#sorted + 1] = {
			k = k,
			v = v,
			priority = priority,
		}
	end

	sorted = self:sortByValues(sorted, {
		prioritykey, true
	}, {
		"k", false
	})

	return iterator, {
		i = 0,
		sorted = sorted,
	}
end

function LIB:Merge(dest, source, recursive)
	if not istable(dest) then
		dest = {dest}
	end

	if not istable(source) then
		source = {source}
	end

	if recursive == nil then
		recursive = true
	end

	local merge = nil
	local cache = {}

	merge = function(D, S)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		if D == S then
			return D
		end

		cache[D] = cache[D] or {}

		if cache[D][S] then
			return D
		end

		cache[D][S] = true

		for k, sv in pairs(S) do
			if isnumber(k) then
				table_insert(D, sv)
				continue
			end

			if recursive then
				local dv = D[k]

				if dv == nil then
					D[k] = sv
					continue
				end

				local isTableSV = istable(sv)
				local isTableDV = istable(dv)

				if isTableSV or isTableDV then
					if not isTableDV then
						D[k] = {dv}
					end

					if not isTableSV then
						sv = {sv}
					end

					D[k] = merge(D[k], sv)
					continue
				end
			end

			D[k] = sv
		end

		return D
	end

	return merge(dest, source)
end

function LIB:Copy(t)
	local deepcopy = nil
	local copies = {}

	deepcopy = function(orig)
		libCoroutine:Yield(libCoroutine.YIELD_TIME_SHORT)

		local copy

		if not istable(orig) then
			if isvector(orig) then
				return Vector(orig)
			end

			if isangle(orig) then
				return Angle(orig)
			end

			return orig
		end

		if copies[orig] then
			return copies[orig]
		end

		local copy = {}
		copies[orig] = copy

		for orig_key, _ in next, orig, nil do
			orig_value = orig[orig_key]

			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end

		setmetatable(copy, deepcopy(getmetatable(orig)))

		return copy
	end

	local copy = deepcopy(t)
	return copy
end

function LIB:Split(t, chunkSize)
	local chunks = {}

	splitSize = tonumber(splitSize or 0) or 0
	if splitSize < 1 then
		splitSize = 1
	end

	if not table.IsSequential(t) then
		t = table.ClearKeys(t)
	end

	local index = 1
	local len = #t

	while true do
		if index > len then
			break
		end

		local chunk = {}

		for i = 1, chunkSize do
			if index > len then
				break
			end

			local v = t[index]
			index = index + 1

			chunk[i] = v
		end

		if #chunk <= 0 then
			break
		end

		chunks[#chunks + 1] = chunk
	end

	return chunks
end


return LIB
