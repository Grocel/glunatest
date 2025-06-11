
local libString = nil
local libClass = nil
local libHook = nil
local libTable = nil
local libLIB = nil
local libHash = nil

local LIB = {}

local g_max_chunksize = 2^14 -- 16 KB
local g_max_totalsize = 2^26 -- 64 MB
local g_max_sendBufferSize = 2^20 -- 1 MB
local g_max_sendAtOnce = math.min(g_max_chunksize * 2 + 256, 2^16 - 256)

local g_gatewayname = ""
local g_gatewaysv = ""
local g_gatewaycl = ""

local g_gatewaysv_status = ""
local g_gatewaycl_status = ""

local g_gateway = ""
local g_gateway_status = ""

local g_senders = nil
local g_receivers = nil

local g_sendDataBuffer = nil
local g_sendDataBufferReady = false
local g_sendDataBufferSize = 0
local g_sendDataBufferNextUpdateTime = 0

local g_playerAliveSend = {}
local g_playerAliveSendNextUpdateTime = 0

local g_hashLen = 0
local g_hashToName = {}

LIB.STATUS_CHUNK_OK = 0
LIB.STATUS_PAYLOAD_OK = 1
LIB.STATUS_CHUNK_ERROR = 2
LIB.STATUS_CHUNK_SIZE_ERROR = 3
LIB.STATUS_PAYLOAD_ERROR = 4
LIB.STATUS_PAYLOAD_SIZE_ERROR = 5
LIB.STATUS_CANCELED = 6
LIB.STATUS_TIMEOUT = 7
LIB.STATUS_NO_RECEIVER = 8
LIB.STATUS_BUFFER_OVERFLOW = 9

local STATUS_NAMES = {}

for k, v in pairs(LIB) do
	if not isnumber(v) then
		continue
	end

	if not isstring(k) then
		continue
	end

	if not string.StartWith(k, "STATUS_") then
		continue
	end

	STATUS_NAMES[v] = k
end

function LIB:GetMaxChunksize()
	return g_max_chunksize
end

function LIB:GetMaxTotalsize()
	return g_max_totalsize
end

function LIB:GetMaxSendBufferSize()
	return g_max_sendBufferSize
end

function LIB:GetSendBufferSize()
	return g_sendDataBufferSize
end

function LIB:GetStatusName(status)
	status = tonumber(status)

	if not status then
		return "<unknown>"
	end

	return STATUS_NAMES[status] or "<unknown>"
end

local function getName(identifier)
	identifier = libString:SanitizeName(identifier)

	local name = libLIB:GetName()
	local networkname = name .. "_net_" .. identifier

	return networkname
end

local function netReadHash()
	return net.ReadData(g_hashLen)
end

local function netWriteHash(hash)
	return net.WriteData(hash, g_hashLen)
end

function LIB:Load(lib)
	libLIB = lib
	libString = lib.string
	libClass = lib.class
	libTimer = lib.timer
	libHook = lib.hook
	libTable = lib.table
	libHash = lib.hash

	g_gatewayname = getName("gateway")

	g_gatewaysv = g_gatewayname .. "_sv"
	g_gatewaycl = g_gatewayname .. "_cl"

	g_gatewaysv_status = g_gatewayname .. "_sv_status"
	g_gatewaycl_status = g_gatewayname .. "_cl_status"

	g_gatewaysv_alive = g_gatewayname .. "_sv_alive"
	g_gatewaycl_alive = g_gatewayname .. "_cl_alive"

	g_gateway = SERVER and g_gatewaysv or g_gatewaycl
	g_gateway_status = SERVER and g_gatewaysv_status or g_gatewaycl_status

	g_gateway_back = SERVER and g_gatewaycl or g_gatewaysv
	g_gateway_status_back = SERVER and g_gatewaycl_status or g_gatewaysv_status

	g_gateway_alive = SERVER and g_gatewaysv_alive or g_gatewaycl_alive
	g_gateway_alive_back = SERVER and g_gatewaycl_alive or g_gatewaysv_alive

	if SERVER then
		util.AddNetworkString(g_gatewaysv)
		util.AddNetworkString(g_gatewaysv_status)
		util.AddNetworkString(g_gatewaycl)
		util.AddNetworkString(g_gatewaycl_status)
		util.AddNetworkString(g_gateway_alive)
		util.AddNetworkString(g_gateway_alive_back)
	end

	g_senders = libClass:CreateObj("network/handler_manager")
	g_receivers = libClass:CreateObj("network/handler_manager")
	g_sendDataBuffer = libClass:CreateObj("ordered_keymap")

	net.Receive(g_gateway_status, function(len, ply)
		g_sendDataBufferReady = true

		if CLIENT then
			ply = NULL
		end

		local sendername = g_hashToName[netReadHash()]

		local status = net.ReadUInt(8)

		local receiverInstanceId = net.ReadUInt(32)
		local senderInstanceId = net.ReadUInt(32)

		if not IsValid(g_senders) then
			return
		end

		g_senders:ResetTimeout(ply)

		if not sendername then
			return
		end

		local sender = g_senders:Get(sendername)
		if not sender then
			return
		end

		if senderInstanceId > 0 and sender:GetID() ~= senderInstanceId then
			return
		end

		sender:SetReceiverID(receiverInstanceId)
		sender:Input(ply, status)
	end)

	net.Receive(g_gateway, function(len, ply)
		g_sendDataBufferReady = true

		if CLIENT then
			ply = NULL
		end

		local receiverhash = netReadHash()
		local receivername = g_hashToName[receiverhash]

		local chunkid = net.ReadUInt(32)

		local totalchunks = net.ReadUInt(32)
		local totalsize = net.ReadUInt(32)

		local len = net.ReadUInt(16)
		local data = net.ReadData(len)

		local hash = netReadHash()

		local receiverInstanceId = net.ReadUInt(32)
		local senderInstanceId = net.ReadUInt(32)

		if not IsValid(g_receivers) then
			self:SendStatus(receiverhash, ply, self.STATUS_NO_RECEIVER, receiverInstanceId, senderInstanceId)
			return
		end

		g_receivers:ResetTimeout(ply)

		if not receivername then
			self:SendStatus(receiverhash, ply, self.STATUS_NO_RECEIVER, receiverInstanceId, senderInstanceId)
			return
		end

		local receiver = g_receivers:Get(receivername)
		if not receiver then
			self:SendStatus(receiverhash, ply, self.STATUS_NO_RECEIVER, receiverInstanceId, senderInstanceId)
			return
		end

		if receiverInstanceId > 0 and receiver:GetID() ~= receiverInstanceId then
			self:SendStatus(receiverhash, ply, self.STATUS_NO_RECEIVER, receiverInstanceId, senderInstanceId)
			return
		end

		receiver:SetSenderID(senderInstanceId)
		receiver:Input(ply, chunkid, data, len, totalchunks, totalsize, hash)
	end)

	net.Receive(g_gateway_alive, function(len, ply)
		if CLIENT then
			ply = NULL
		end

		if not IsValid(g_receivers) then
			return
		end

		if not IsValid(g_senders) then
			return
		end

		g_receivers:ResetTimeout(ply)
		g_senders:ResetTimeout(ply)
	end)

	g_sendDataBufferReady = true

	libHook:AddIgnorePauseThink("networktick", function()
		self:KeepAlive()
		self:Tick()
	end)
end

function LIB:Ready(lib)
	g_hashLen = #self:Hash("How long am I?")

	self:GetLoopbackSetup()
end

function LIB:Unload(lib)
	if IsValid(g_senders) then
		g_senders:Remove()
		g_senders = nil
	end

	if IsValid(g_receivers) then
		g_receivers:Remove()
		g_receivers = nil
	end

	if IsValid(g_sendDataBuffer) then
		g_sendDataBuffer:Remove()
		g_sendDataBuffer = nil
	end
end

local function hash_concat(values)
	values = values or {}

	local tmp = {}

	for i, v in ipairs(values) do
		table.insert(tmp, tostring(v))
	end

	table.insert(tmp, "vjnsg")
	tmp = table.concat(tmp, "_")

	return libHash:MD5_SUM(tmp)
end

function LIB:Hash(data, len)
	len = len or #data

	local s1 = ""
	local s2 = ""

	if len > 0 then
		s1 = data[math.ceil(len / 2)]
		s2 = data[math.ceil(len / 4)]
	end

	local hash = hash_concat({
		"agx", s2, data, len, s1, g_gatewayname, "cvd"
	})

	return hash
end

function LIB:HashCompare(h1, h2)
	if not h1 then return false end
	if not h2 then return false end

	if #h1 ~= g_hashLen then return false end
	if #h2 ~= g_hashLen then return false end

	if h1 ~= h2 then return false end

	return true
end

function LIB:CalculateAndAddHash(rawdata)
	local calculatedHash = self:Hash(rawdata)

	rawdata = calculatedHash .. rawdata

	return rawdata
end

function LIB:ValidateAndRemoveHash(rawdata)
	local storedHash = string.sub(rawdata, 1, g_hashLen)

	rawdata = string.sub(rawdata, g_hashLen + 1)

	local calculatedHash = self:Hash(rawdata)
	if not self:HashCompare(storedHash, calculatedHash) then
		return nil
	end

	return rawdata
end

function LIB:SendAlive(ply)
	if SERVER then
		if not IsValid(ply) then
			return
		end
	end

	ply = ply or NULL
	g_playerAliveSend[ply] = true
end

function LIB:SendChunk(sender, ply, curchunk, totalchunks, totalsize)
	if not IsValid(g_sendDataBuffer) then
		return false
	end

	if g_sendDataBufferSize > g_max_sendBufferSize then
		return false
	end

	if not IsValid(sender) then
		return false
	end

	if SERVER then
		if not IsValid(ply) then
			return false
		end
	end

	local hash = sender:GetHash()

	local chunkindex = curchunk.index
	local len = curchunk.len

	local packetSize = len + g_hashLen * 2 + 20
	local receiverInstanceId = sender:GetReceiverID()
	local senderInstanceId = sender:GetID()

	local key = libTable:Hash({
		tostring(self),
		"SendChunk",
		hash,
		chunkindex,
		len,
		curchunk,
		totalchunks,
		totalsize,
		receiverInstanceId,
		senderInstanceId,
		packetSize,
	})

	local item = g_sendDataBuffer:Get(key)

	if not item or not item.plys or not item.func then
		g_sendDataBufferSize = g_sendDataBufferSize + packetSize

		item = {
			plys = {},
			func = function(plys)
				net.Start(g_gateway_back)
					netWriteHash(hash)
					net.WriteUInt(chunkindex, 32)

					net.WriteUInt(totalchunks, 32)
					net.WriteUInt(totalsize, 32)

					net.WriteUInt(len, 16)
					net.WriteData(curchunk.data, len)
					netWriteHash(curchunk.hash)

					net.WriteUInt(receiverInstanceId, 32)
					net.WriteUInt(senderInstanceId, 32)

				if SERVER then
					net.Send(plys)
				else
					net.SendToServer()
				end

				return true
			end,
			size = packetSize,
		}
	end

	if SERVER then
		item.plys[ply] = ply
	end

	g_sendDataBuffer:PushRight(key, item)
	return true
end

function LIB:SendStatus(receiverOrHash, ply, status, receiverInstanceId, senderInstanceId)
	if not IsValid(g_sendDataBuffer) then
		return false
	end

	if g_sendDataBufferSize > g_max_sendBufferSize then
		return false
	end

	if SERVER then
		if not IsValid(ply) then
			return false
		end
	end

	local packetSize = 9 + g_hashLen
	local hash = nil

	if status ~= self.STATUS_NO_RECEIVER then
		if not IsValid(receiverOrHash) then
			return false
		end

		hash = receiverOrHash:GetHash()
		receiverInstanceId = receiverOrHash:GetID()
		senderInstanceId = receiverOrHash:GetSenderID()
	else
		hash = receiverOrHash
		receiverInstanceId = receiverInstanceId or 0
		senderInstanceId = senderInstanceId or 0
	end

	local key = libTable:Hash({
		tostring(self),
		"SendStatus",
		hash,
		status,
		receiverInstanceId,
		senderInstanceId,
		packetSize,
	})

	local item = g_sendDataBuffer:Get(key)

	if not item or not item.plys or not item.func then
		g_sendDataBufferSize = g_sendDataBufferSize + packetSize

		item = {
			plys = {},
			func = function(plys)
				net.Start(g_gateway_status_back)
					netWriteHash(hash)

					net.WriteUInt(status, 8)
					net.WriteUInt(receiverInstanceId, 32)
					net.WriteUInt(senderInstanceId, 32)

				if SERVER then
					net.Send(plys)
				else
					net.SendToServer()
				end

				return true
			end,
			size = packetSize,
		}
	end

	if SERVER then
		item.plys[ply] = ply
	end

	g_sendDataBuffer:PushRight(key, item)
	return true
end

function LIB:KeepAlive()
	if g_playerAliveSendNextUpdateTime > 0 and g_playerAliveSendNextUpdateTime > SysTime() then
		return
	end

	g_playerAliveSendNextUpdateTime = SysTime() + 0.5

	local plys = {}

	for ply, bool in pairs(g_playerAliveSend) do
		g_playerAliveSend[ply] = nil

		if not bool then
			continue
		end

		if SERVER then
			if not IsValid(ply) then
				continue
			end

			if not ply:IsPlayer() then
				continue
			end

			if ply:IsBot() then
				continue
			end
		end

		plys[#plys + 1] = ply
	end

	if #plys <= 0 then
		return
	end

	net.Start(g_gateway_alive_back)

	if SERVER then
		net.Send(plys)
	else
		net.SendToServer()
	end
end

local waittime = 0

function LIB:Tick()
	if not IsValid(g_sendDataBuffer) then
		return
	end

	if not g_sendDataBufferReady then
		return
	end

	if g_sendDataBufferNextUpdateTime > 0 and g_sendDataBufferNextUpdateTime > SysTime() then
		return
	end

	g_sendDataBufferNextUpdateTime = SysTime() + waittime
	waittime = 0.2

	local sizeLeft = g_max_sendAtOnce

	while true do
		local key, item = g_sendDataBuffer:GetLeft()
		if not item then
			g_sendDataBufferReady = true
			break
		end

		local func = item.func
		local size = item.size
		local plys = item.plys

		if not size then
			g_sendDataBuffer:PopLeft()
			continue
		end

		if not isfunction(func) then
			g_sendDataBufferSize = math.max(g_sendDataBufferSize - size, 0)
			g_sendDataBuffer:PopLeft()
			continue
		end

		if sizeLeft < size then
			break
		end

		g_sendDataBufferSize = math.max(g_sendDataBufferSize - size, 0)

		if SERVER then
			if not plys then
				g_sendDataBuffer:PopLeft()
				continue
			end

			local filteredPlys = {}

			for k, ply in pairs(plys) do
				if not IsValid(ply) then
					continue
				end

				if not ply:IsPlayer() then
					continue
				end

				if ply:IsBot() then
					continue
				end

				filteredPlys[#filteredPlys + 1] = ply
			end

			if #filteredPlys <= 0 then
				g_sendDataBuffer:PopLeft()
				continue
			end

			waittime = math.min(#filteredPlys * 0.25, 2)

			if not func(filteredPlys) then
				g_sendDataBuffer:PopLeft()
				continue
			end
		else
			if not func() then
				g_sendDataBuffer:PopLeft()
				continue
			end
		end

		g_sendDataBuffer:PopLeft()

		g_sendDataBufferReady = false
		sizeLeft = math.max(sizeLeft - size, 0)
	end
end

function LIB:CreateReceiver(name)
	if not IsValid(g_receivers) then
		return
	end

	name = tostring(name or "")

	local hash = self:Hash(name)
	g_hashToName[hash] = name

	local obj = g_receivers:CreateManagedObj(name, "network/handler_receiver", hash)
	return obj
end

function LIB:CreateSender(name)
	if not IsValid(g_senders) then
		return
	end

	name = tostring(name or "")

	local hash = self:Hash(name)
	g_hashToName[hash] = name

	local obj = g_senders:CreateManagedObj(name, "network/handler_sender", hash)
	return obj
end

function LIB:GetLoopbackSetup()
	local reCreateLoopBack = nil

	reCreateLoopBack = function()
		local receiver = self:CreateReceiver("test_loopback")
		local receiverBack = self:CreateReceiver("test_loopback_back")

		local sender = self:CreateSender("test_loopback")
		local senderBack = self:CreateSender("test_loopback_back")

		if not IsValid(receiver) then
			return
		end

		if not IsValid(sender) then
			return
		end

		receiver.OnRemove = reCreateLoopBack
		receiverBack.OnRemove = reCreateLoopBack
		sender.OnRemove = reCreateLoopBack
		senderBack.OnRemove = reCreateLoopBack

		receiver.OnReceive = function(this, stream, ply)
			senderBack:Send(ply, stream)
		end

		return receiverBack, sender
	end

	return reCreateLoopBack()
end

return LIB
