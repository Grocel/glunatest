local libPrint = nil

local LIB = {}

local g_maxMemory = 2 ^ 19 * 1.5 -- 768 MB
local g_swapCounter = 0
local g_traffic = 0

function LIB:Load(lib)
	libPrint = lib.print
end

function LIB:Ready(lib)
	self:Cleanup()
end

function LIB:Cleanup()
	local memory = self:GetUsage()
	g_traffic = g_traffic + memory
	g_swapCounter = g_swapCounter + 1

	collectgarbage("collect")
end

function LIB:GetUsage()
	return collectgarbage("count")
end

function LIB:GetSwapCount()
	return g_swapCounter
end

function LIB:GetTrafficEstimation()
	return g_traffic + self:GetUsage()
end

function LIB:PreventOverflow()
	for i = 1, 2 do
		if self:GetUsage() > g_maxMemory then
			self:Cleanup()
		end
	end

	local usage = self:GetUsage()

	if usage > g_maxMemory then
		-- error if memory can't be freed to prevent crashes or other undefined behavours
		libPrint:errorf("Unresolvable memory overflow detected (Usage: %0.1f / %0.1f MB)", 2, math.Round(usage / 1024, 1), math.Round(g_maxMemory / 1024, 1))
	end
end

return LIB
