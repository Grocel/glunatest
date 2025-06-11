local CLASS = {}
local BASE = nil

CLASS.baseClassname = "result/base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
end

function CLASS:Create(gLunaTest, data)
	BASE.Create(self, data)

	self.getGLunaTest = function(this)
		return gLunaTest
	end
end

function CLASS:getTotalErrors()
	local errors = self:getErrors()
	local failed = self:getFailed()

	local totalerrors = errors + failed

	if totalerrors <= 0 then
		totalerrors = self:getExitcode()
	end

	return totalerrors
end

function CLASS:getTotalPassed()
	local passed = self:getPassed()
	local skipped = self:getSkipped()

	return passed + skipped
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
