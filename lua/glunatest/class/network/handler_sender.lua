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

	self.playerBufferClass = "network/playerbuffer_sender"
	self:SetReceiverID(0)
end

function CLASS:Remove()
	self:SetReceiverID(0)

	self.OnSend = function() end
	self.OnDone = function() end
	self.OnTransmitted = function() end
	self.OnTimeout = function() end
	self.OnCancel = function() end
	self.OnError = function() end
	self.OnProgress = function() end

	BASE.Remove(self)
end

function CLASS:SetReceiverID(id)
	self.receiverInstanceId = tonumber(id or 0) or 0
end

function CLASS:GetReceiverID()
	return self.receiverInstanceId
end

function CLASS:Input(ply, status)
	if not self:IsValid() then return end

	libMemory:PreventOverflow()

	local playerbuffer = self:GetPlayerBuffer(ply)
	if not playerbuffer then
		return
	end

	playerbuffer:SetChunkStatus(status)
end

function CLASS:Output(playerbuffer, curchunk, totalchunks, totalsize)
	if not self:IsValid() then return end

	libMemory:PreventOverflow()

	local ply = playerbuffer:GetPlayer()
	return libNet:SendChunk(self, ply, curchunk, totalchunks, totalsize)
end

function CLASS:Send(plys, stream)
	if not self:IsValid() then return end

	if SERVER then
		if not plys then
			plys = player.GetHumans()
		end
	end

	plys = self:GetPlayersFromTable(plys)

	stream = self:CreateObj("stream", stream)

	self:SetReceiverID(0)

	if SERVER then
		self:OnSend(stream, plys)
	else
		self:OnSend(stream)
	end

	local rawdata = tostring(stream)
	rawdata = libNet:CalculateAndAddHash(rawdata)

	local chunks = self:CreateObj("queue")

	local totalsize = #rawdata
	local maxChunksize = libNet:GetMaxChunksize()
	local position = 0

	while true do
		if position > totalsize then
			break
		end

		local startposition = position
		position = position + maxChunksize

		local endposition = math.Clamp(position, 0, totalsize)
		local len = math.Clamp(endposition - startposition, 0, maxChunksize)

		local index = chunks:GetSize() + 1

		chunks:PushRight({
			len = len,
			index = index,
			startposition = startposition,
			endposition = endposition,
		})

	end

	chunks:Normalize()

	local playerbuffers = {}

	for i, ply in ipairs(plys) do
		local playerbuffer = self:GetPlayerBuffer(ply)
		if not playerbuffer then
			continue
		end

		local playerchunks = chunks:Copy()

		playerbuffer:Push({
			chunks = playerchunks,
			totalchunks = playerchunks:GetSize(),
			totalsize = totalsize,
			data = rawdata,
		})

		playerbuffers[#playerbuffers + 1] = playerbuffer
	end

	for i, v in ipairs(playerbuffers) do
		if v.running then
			continue
		end

		v:SendNextChunk()
	end
end

function CLASS:OnSend(stream, plys)
	-- override me
end

function CLASS:OnTransmitted(ply)
	-- override me
end

function CLASS:OnDone(ply)
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
