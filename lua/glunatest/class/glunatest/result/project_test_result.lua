local CLASS = {}
local BASE = nil

CLASS.baseClassname = "result/base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

local function getSum(results, funcname)
	local sum = 0

	for i, v in ipairs(results) do
		sum = sum + v[funcname](v)
	end

	return sum
end

function CLASS:Create(gLunaTestSetup, data)
	BASE.Create(self, data)

	self.getGLunaTestSetup = function(this)
		return gLunaTestSetup
	end
end

function CLASS:getTime()
	if not self._time then
		self._time = getSum(self:getResults(), "getTime")
	end

	return self._time
end

function CLASS:getAssertions()
	if not self._assertions then
		self._assertions = getSum(self:getResults(), "getAssertions")
	end

	return self._assertions
end

function CLASS:getPassed()
	if not self._passed then
		self._passed = getSum(self:getResults(), "getPassed")
	end

	return self._passed
end

function CLASS:getFailed()
	if not self._failed then
		self._failed = getSum(self:getResults(), "getFailed")
	end

	return self._failed
end

function CLASS:getErrors()
	if not self._errors then
		self._errors = getSum(self:getResults(), "getErrors")
	end

	return self._errors
end

function CLASS:getSkipped()
	if not self._skipped then
		self._skipped = getSum(self:getResults(), "getSkipped")
	end

	return self._skipped
end

function CLASS:getTotalErrors()
	if not self._totalErrors then
		self._totalErrors = getSum(self:getResults(), "getTotalErrors")
	end

	return self._totalErrors
end

function CLASS:getTotalPassed()
	if not self._totalPassed then
		self._totalPassed = getSum(self:getResults(), "getTotalPassed")
	end

	return self._totalPassed
end

function CLASS:hasAssertions()
	local assertions = self:getAssertions()
	return assertions > 0
end

function CLASS:hasErrors()
	local errors = self:getTotalErrors()
	return errors > 0
end

function CLASS:hasPassed()
	if not self:hasAssertions() then
		return false
	end

	if self:getTotalPassed() <= 0 then
		return false
	end

	local errors = self:getTotalErrors()
	return errors <= 0
end

function CLASS:hasSkipped()
	if not self:hasAssertions() then
		return true
	end

	if self:getTotalPassed() <= 0 then
		return true
	end

	local skipped = self:getSkipped()
	return skipped > 0
end

function CLASS:hasPassedStrict()
	if self:hasSkipped() then
		return false
	end

	return self:hasPassed()
end

return CLASS
