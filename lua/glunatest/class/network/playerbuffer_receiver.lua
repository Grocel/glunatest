local libNet = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "network/playerbuffer_base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libNet = classLib.LIB.net
end

function CLASS:Create(...)
	BASE.Create(self, ...)
end

function CLASS:Remove()
	BASE.Remove(self)
end

function CLASS:Clear()
	self.receivedSize = 0

	BASE.Clear(self)
end

function CLASS:SendStatus(status)
	if not self:IsValid() then return end

	local handler = self:GetHandler()
	self:ResetTimeout()

	local success = handler:Output(self, status)
	if not success then
		self:OnError(libNet.STATUS_BUFFER_OVERFLOW)
		self:Remove()
	end
end

function CLASS:ProcessFinalData()
	if not self:IsValid() then return end

	local ply = self.ply
	local handler = self:GetHandler()
	local data = self.packets

	return handler:ProcessFinalData(data, ply)
end

function CLASS:Reset()
	BASE.Reset(self)

	if self.running then
		if self:GetSize() > 0 then
			self:SendStatus(libNet.STATUS_CANCELED)
		end
		self:OnCancel()
	end

	self:StopTimeout()
	self.running = false

	self:Clear()
end

function CLASS:ProcessReceivedData(chunkid, data, len, totalchunks, totalsize, sendhash)
	if not self:IsValid() then return end

	if len > libNet:GetMaxChunksize() then
		self:OnError(libNet.STATUS_CHUNK_SIZE_ERROR)
		self:SendStatus(libNet.STATUS_CHUNK_SIZE_ERROR)

		self:Remove()
		return
	end

	if totalsize > libNet:GetMaxTotalsize() then
		self:OnError(libNet.STATUS_PAYLOAD_SIZE_ERROR)
		self:SendStatus(libNet.STATUS_PAYLOAD_SIZE_ERROR)

		self:Remove()
		return
	end

	local datahash = libNet:Hash(data, len)
	if not libNet:HashCompare(datahash, sendhash) then
		self:OnError(libNet.STATUS_CHUNK_ERROR)
		self:SendStatus(libNet.STATUS_CHUNK_ERROR)

		self:Remove()
		return
	end

	self.running = true

	self:Push({
		data = data,
		len = len,
	})

	self.receivedSize = self.receivedSize + len

	if self.receivedSize > totalsize then
		self:OnError(libNet.STATUS_CHUNK_SIZE_ERROR)
		self:SendStatus(libNet.STATUS_CHUNK_SIZE_ERROR)

		self:Remove()
		return
	end

	local startposition = self.receivedSize - len
	local endposition = self.receivedSize

	local sendmore = self:OnProgress({
		len = len,
		index = chunkid,
		startposition = startposition,
		endposition = endposition,
		totalchunks = totalchunks,
		totalsize = totalsize,
		fraction = math.Clamp(endposition / totalsize, 0, 1),
	})

	if not sendmore then
		self:Remove()
		return
	end

	local lastchunk = self:GetSize() >= totalchunks

	if not lastchunk then
		self:SendStatus(libNet.STATUS_CHUNK_OK)
		return
	end

	local stream = self:ProcessFinalData()
	if not stream then
		self:OnError(libNet.STATUS_PAYLOAD_ERROR)
		self:SendStatus(libNet.STATUS_PAYLOAD_ERROR)

		self:Remove()
		return
	end

	self.running = false

	self:SendStatus(libNet.STATUS_PAYLOAD_OK)
	self:Reset()

	local handler = self:GetHandler()
	handler:SetSenderID(0)

	self:OnReceive(stream)
	self:Remove()
end

function CLASS:Timeout()
	if not self:IsValid() then return end

	self:SendStatus(libNet.STATUS_TIMEOUT)

	BASE.Timeout(self)
end

return CLASS
