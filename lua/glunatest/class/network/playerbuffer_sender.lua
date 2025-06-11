local libNet = nil
local libPrint = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "network/playerbuffer_base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()
	libNet = classLib.LIB.net
	libPrint = classLib.LIB.print
end

function CLASS:Create(...)
	BASE.Create(self, ...)
end

function CLASS:Remove()
	BASE.Remove(self)
end

function CLASS:SetChunkStatus(status)
	if not self:IsValid() then return end

	local packet = self:Read()
	if not packet then
		self:Remove()
		return
	end

	local chunks = packet.chunks
	local curchunk = chunks:GetLeft()

	if not curchunk then
		self:Reset()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_TIMEOUT then
		self:Timeout()
		return
	end

	if status == libNet.STATUS_NO_RECEIVER then
		self:OnError(libNet.STATUS_NO_RECEIVER)
		self:Remove()
		return
	end

	if status == libNet.STATUS_CHUNK_SIZE_ERROR then
		self:OnError(libNet.STATUS_CHUNK_SIZE_ERROR)
		self:Reset()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_PAYLOAD_SIZE_ERROR then
		self:OnError(libNet.STATUS_PAYLOAD_SIZE_ERROR)
		self:Reset()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_CHUNK_ERROR then
		self:OnError(libNet.STATUS_CHUNK_ERROR)
		self:Reset()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_PAYLOAD_ERROR then
		self:OnError(libNet.STATUS_PAYLOAD_ERROR)
		self:Reset()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_CANCELED then
		self:Reset()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_CHUNK_OK then
		chunks:PopLeft()
		self:SendNextChunk()
		return
	end

	if status == libNet.STATUS_PAYLOAD_OK then
		self.running = false
		self:Reset()

		self:OnTransmitted(ply)
		self:SendNextChunk()
		return
	end

	libPrint:warnf("Playerbuffer (%s) received an unknown status code: %d (%s)", self, status, libNet:GetStatusName(status))
	self:OnError(status)
	self:Reset()
	self:SendNextChunk()
end

function CLASS:SendChunk(curchunk, totalchunks, totalsize)
	if not self:IsValid() then return end
	if not curchunk then return end

	local handler = self:GetHandler()
	self:ResetTimeout()

	local success = handler:Output(self, curchunk, totalchunks, totalsize)
	if not success then
		self:OnError(libNet.STATUS_BUFFER_OVERFLOW)
		self:Remove()
	end
end

function CLASS:Reset()
	BASE.Reset(self)

	if self.running then
		self:OnCancel()
	end

	self.running = false
	self:Pop()
end

function CLASS:SendNextChunk()
	if not self:IsValid() then return end

	local packet = self:Read()
	if not packet then
		self:Remove()
		return
	end

	local ply = self.ply
	local chunks = packet.chunks
	local totalchunks = packet.totalchunks
	local totalsize = packet.totalsize

	local curchunk = chunks:GetLeft()
	if not curchunk then
		self:Reset()
		return
	end

	local curdata = string.sub(packet.data, curchunk.startposition + 1, curchunk.endposition)
	local hash = libNet:Hash(curdata, curchunk.len)

	curchunk.data = curdata
	curchunk.hash = hash

	local startposition = curchunk.startposition
	local endposition = curchunk.endposition

	local data = {
		len = curchunk.len,
		index = curchunk.index,
		startposition = startposition,
		endposition = endposition,
		totalchunks = totalchunks,
		totalsize = totalsize,
		fraction = math.Clamp(endposition / totalsize, 0, 1),
	}

	self.running = true

	local sendmore = self:OnProgress(data, ply)

	if not sendmore then
		self:Reset()
		return
	end

	self:SendChunk(curchunk, totalchunks, totalsize)
	return
end

return CLASS
