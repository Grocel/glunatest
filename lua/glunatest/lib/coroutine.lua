local libPrint = nil
local libHook = nil
local libClass = nil

local LIB = {}

LIB.YIELD_TIME_LONG = 0.07
LIB.YIELD_TIME_SHORT = 0.014
LIB.YIELD_TIME_REALTIME = 0.0035

local g_threads = {}
local g_threadsOrdered = {}
local g_functionsWithYield = {}

local g_ticktimelastset = 0
local g_ticktimeleft = 0


local coroutine = coroutine
local coroutine_running = coroutine.running
local coroutine_resume = coroutine.resume
local coroutine_status = coroutine.status
local coroutine_create = coroutine.create
local coroutine_yield = coroutine.yield

local string = string
local string_format = string.format


local IsValid = IsValid
local SysTime = SysTime
local ipairs = ipairs
local pairs = pairs

local istable = istable
local isstring = isstring
local isfunction = isfunction
local tostring = tostring
local tonumber = tonumber

local assert = assert
local xpcall = xpcall
local setmetatable = setmetatable

function LIB:Load(lib)
	libPrint = lib.print
	libHook = lib.hook
	libClass = lib.class

	local function tick()
		if #g_threadsOrdered <= 0 then
			return
		end

		local threadsOrdered = {}
		local threads = {}

		for i, thread in ipairs(g_threadsOrdered) do
			if not IsValid(thread) then
				continue
			end

			threadsOrdered[#threadsOrdered + 1] = thread
			threads[thread.coroutineId] = thread
		end

		g_threads = threads
		g_threadsOrdered = threadsOrdered

		local ticktime = SysTime()

		while true do
			if #g_threadsOrdered <= 0 then
				g_ticktimelastset = 0
				return
			end

			for i, thread in ipairs(g_threadsOrdered) do
				if not IsValid(thread) then
					g_ticktimelastset = 0
					return
				end

				local innermostthread = thread:GetInnermostFirstChild()

				if not IsValid(innermostthread) then
					innermostthread = thread
				end

				local time = nil
				local err = nil

				xpcall(function()
					time = innermostthread:Resume()
				end, function(thiserr)
					time = nil
					err = thiserr
				end)

				if not time then
					g_ticktimelastset = 0

					if err and err ~= "" then
						error(err)
					end

					return
				end

				if g_ticktimelastset ~= time then
					g_ticktimelastset = time
					return
				end

				local timeused = SysTime() - ticktime

				if timeused >= time then
					g_ticktimelastset = time
					return
				end

				break
			end
		end
	end

	libHook:AddIgnorePauseThink("threads", tick)
end

function LIB:Unload(lib)
	for k, thread in pairs(g_threads) do
		if not IsValid(thread) then
			continue
		end

		thread.callback = nil
		thread:Remove()
	end

	for k, thread in pairs(g_threadsOrdered) do
		if not IsValid(thread) then
			continue
		end

		thread.callback = nil
		thread:Remove()
	end

	g_threads = {}
	g_threadsOrdered = {}
end

function LIB:GetThread(co)
	if co == nil then
		co = coroutine_running()
	end

	if co == nil then
		return nil
	end

	local id = nil

	if istable(co) and co.coroutine and co.coroutineId then
		id = tostring(co.coroutineId)
	else
		id = tostring(co)
	end

	return g_threads[id]
end


function LIB:Create(func, parent, callbackOnExit)
	if parent then
		parent = self:GetThread(parent)
	end

	local thread = libClass:CreateObj("thread", func, parent, callbackOnExit)
	local id = thread.coroutineId

	g_threads = g_threads or {}
	g_threadsOrdered = g_threadsOrdered or {}

	if not g_threads[id] then
		g_threads[id] = thread
		g_threadsOrdered[#g_threadsOrdered + 1] = thread
	end

	if parent then
		parent:AddChild(thread)
	end

	return thread
end

function LIB:Yield(...)
	local thread = self:GetThread()

	if not IsValid(thread) then
		return nil
	end

	return thread:Yield(...)
end

function LIB:AddYieldToFunction(oldfunc, time)
	assert(isfunction(oldfunc), "bad argument #1, expected function")
	g_functionsWithYield = g_functionsWithYield or {}

	if g_functionsWithYield[oldfunc] and g_functionsWithYield[oldfunc].newfunc then
		g_functionsWithYield[oldfunc].time = time
		return g_functionsWithYield[oldfunc].newfunc
	end

	local newfunc = function(...)
		local d = g_functionsWithYield[oldfunc] or {}
		local t = d.time

		self:Yield(t)
		return oldfunc(...)
	end

	g_functionsWithYield[oldfunc] = {
		oldfunc = oldfunc,
		newfunc = newfunc,
		time = time or 0,
	}

	return newfunc
end

function LIB:WaitUntil(conditionFunc, maxtime, level)
	assert(isfunction(conditionFunc), "bad argument #1, expected function")

	level = tonumber(level or 0) or 0

	if level <= 0 then
		level = 1
	end

	maxtime = tonumber(maxtime or 0) or 0

	local backupmaxtime = 180

	if maxtime <= 0 then
		maxtime = backupmaxtime
	end

	local t0 = SysTime()
	while true do
		local t1 = SysTime()
		local delta = t1 - t0

		if conditionFunc(delta) then
			return
		end

		if delta > maxtime then
			if maxtime < 1 then
				maxtime = maxtime * 1000
				libPrint:errorf("Awaited condition did not occur within the set time. (%0.2fms)", level + 1, maxtime)
			else
				libPrint:errorf("Awaited condition did not occur within the set time. (%0.2fs)", level + 1, maxtime)
			end
		end

		local thread = self:GetThread()

		if not thread or thread:IsSkippingYields() then
			libPrint:error("Can not await condition in a non-asynchronous context", level + 1)
		end

		thread:Yield(0)
	end
end

function LIB:GetSyncObject(callback)
	assert(isfunction(callback), "bad argument #1, expected function")
	return libClass:CreateObj("sync", callback)
end

return LIB
