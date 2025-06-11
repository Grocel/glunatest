local libNet = nil
local libMemory = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "network/handler"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libNet = classLib.LIB.net
	libMemory = classLib.LIB.memory
end

function CLASS:Create(...)
	BASE.Create(self, ...)

	self.playerBufferClass = "network/playerbuffer_receiver"
	self:SetSenderID(0)
end

function CLASS:Remove()
	self:SetSenderID(0)

	self.OnDone = function() end
	self.OnReceive = function() end
	self.OnTimeout = function() end
	self.OnCancel = function() end
	self.OnError = function() end
	self.OnProgress = function() end

	BASE.Remove(self)
end

function CLASS:SetSenderID(id)
	self.senderInstanceId = tonumber(id or 0) or 0
end

function CLASS:GetSenderID()
	return self.senderInstanceId
end

function CLASS:Input(ply, chunkid, data, len, totalchunks, totalsize, sendhash)
	if not self:IsValid() then return end

	libMemory:PreventOverflow()

	local playerbuffer = self:GetPlayerBuffer(ply)
	if not playerbuffer then
		return
	end

	playerbuffer:ProcessReceivedData(chunkid, data, len, totalchunks, totalsize, sendhash)
end


function CLASS:Output(playerbuffer, status)
	if not self:IsValid() then return end

	libMemory:PreventOverflow()

	local ply = playerbuffer:GetPlayer()
	return libNet:SendStatus(self, ply, status)
end

function CLASS:ProcessFinalData(receivedChunks)
	if not self:IsValid() then return end

	local rawdata = {}

	for _, receivedChunk in ipairs(receivedChunks:ToTable()) do
		rawdata[#rawdata + 1] = receivedChunk.data
	end

	rawdata = table.concat(rawdata)

	rawdata = libNet:ValidateAndRemoveHash(rawdata)
	if not rawdata then
		return nil
	end

	return self:CreateObj("stream", rawdata)
end

function CLASS:OnDone(ply)
	-- override me
end

function CLASS:OnReceive(stream, ply)
	-- override me
end

function CLASS:OnTimeout(ply)
	-- override me
end

function CLASS:OnCancel(ply)
	-- override me
end

function CLASS:OnError(status, ply)
	-- override me
end

function CLASS:OnProgress(data, ply)
	return true
end

return CLASS
