local CLASS = {}
local libCoroutine = nil

local BASE = nil

CLASS.baseClassname = "base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()

	libCoroutine = classLib.LIB.coroutine
end

function CLASS:Create(callback)
	assert(isfunction(callback), "bad argument #1, expected function")

	BASE.Create(self)

	self._calls = {}
	self._syncresults = nil
	self._callbackInternal = callback

	self._callback = function(...)
		return self(...)
	end

	self:Reset()
end

function CLASS:Remove()
	self:Reset()

	self._callbackInternal = nil
	self._callback = nil
	self._calls = nil
	self._syncresults = nil

	BASE.Remove(self)
end

function CLASS:IsValid()
	if not BASE.IsValid(self) then
		return false
	end

	if not self._callback then
		return false
	end

	if not self._callbackInternal then
		return false
	end

	if not self._calls then
		return false
	end

	return true
end


function CLASS:ToFunction()
	return self._callback
end

function CLASS:Reset()
	self._calls = {}
	self._syncresults = nil
	self._hasWaitUntilError = nil
end

function CLASS:SyncOptional(maxtime, minCallTimes)
	if not self:IsValid() then
		return nil
	end

	if self._syncresults then
		return self._syncresults
	end

	local results = nil
	local err = nil

	xpcall(function(this)
		results = this:Sync(maxtime, minCallTimes)
	end, function(thiserr)
		err = thiserr
	end, self)

	if err and not self._hasWaitUntilError then
		self._syncresults = nil
		error(err, 2)
	end

	return results
end

function CLASS:Sync(maxtime, minCallTimes)
	if not self:IsValid() then
		return nil
	end

	if self._syncresults then
		return self._syncresults
	end

	minCallTimes = tonumber(minCallTimes or 0) or 0

	if minCallTimes <= 0 then
		minCallTimes = 1
	end

	local err = nil
	self._hasWaitUntilError = nil

	xpcall(function(this)
		libCoroutine:WaitUntil(function()
			return not IsValid(this) or #this._calls >= minCallTimes
		end, maxtime, 2)
	end, function(thiserr)
		err = thiserr
	end, self)

	if not self:IsValid() then
		self._syncresults = nil
		self._hasWaitUntilError = nil

		return nil
	end

	if err then
		self._syncresults = nil
		self._hasWaitUntilError = true

		error(err, 2)
	end

	self._hasWaitUntilError = nil

	local results = {}

	for i, v in ipairs(self._calls) do
		if not v.status then
			results = nil
			self._syncresults = nil

			error(v.err, 2)
		end

		local result = self:CreateObj("result/sync_result", {
			arguments = v.args,
			Return = v.returndata,
		})

		result:SetSyncObject(self)

		results[#results + 1] = result
	end

	self._syncresults = results

	return results
end

function CLASS:ToString()
	local r = BASE.ToString(self)
	if not self:IsValid() then
		return r
	end

	r = r .. string.format("[%s]", tostring(self._callbackInternal))
	return r
end

function CLASS:IsEqual(other)
	if isfunction(other) then
		return self._callbackInternal == other
	end

	if not istable(other) then
		return false
	end

	return self._callbackInternal == other._callbackInternal
end

function CLASS:__call(...)
	if not self:IsValid() then
		return nil
	end

	local callbackerr = nil
	self._syncresults = nil

	local returndata = {
		xpcall(self._callbackInternal, function(err)
			if err == nil or err == "" then
				err = "unknown error"
			end

			callbackerr = err
			return nil
		end, ...)
	}

	local status = returndata[1]

	self._calls[#self._calls + 1] = {
		err = callbackerr,
		status = status,
		returndata = returndata,
		args = {...},
	}

	if not status then
		return nil
	end

	return unpack(returndata, 2)
end

function CLASS:__unm()
	return self._callback
end

return CLASS
