local libTable = nil

local CLASS = {}
local BASE = nil

CLASS.baseClassname = "network/base"

function CLASS:ClassLoad(classLib)
	BASE = self:GetBaseClass()

	libTable = classLib.LIB.table
end

function CLASS:Create(hash)
	BASE.Create(self)

	self.playerBufferClass = "network/playerbuffer_base"
	self.playerBufferManager = self:CreateObj("object_manager/manager")
	self.hash = hash

	self.timeout = 4
end

function CLASS:Remove()
	if self.playerBufferManager then
		self.playerBufferManager:Remove()
		self.playerBufferManager = nil
	end

	self.hash = nil

	BASE.Remove(self)
end

function CLASS:IsValid()
	if not BASE.IsValid(self) then
		return false
	end

	if not IsValid(self.playerBufferManager) then
		return false
	end

	if not self.hash then
		return false
	end

	return true
end

function CLASS:GetHash()
	return self.hash
end

function CLASS:GetTimeout()
	return self.timeout
end

function CLASS:SetTimeout(timeout)
	timeout = tonumber(timeout or 0) or 0

	if timeout < 0 then
		timeout = 0
	end

	self.timeout = timeout
end

function CLASS:StopTimeout(ply)
	if not self:IsValid() then return end

	local buffer = self:GetPlayerBuffer(ply ,true)
	if not buffer then
		return
	end

	buffer:StopTimeout()
end

function CLASS:ResetTimeout(ply)
	if not self:IsValid() then return end

	local buffer = self:GetPlayerBuffer(ply, true)
	if not buffer then
		return
	end

	buffer:ResetTimeout()
end

function CLASS:SendAlive(ply)
	if not self:IsValid() then return end

	local manager = self:GetManager()
	if not IsValid(manager) then return end

	manager:SendAlive(ply)
end

function CLASS:GetPlayerBuffer(ply, doNotCreate)
	local id = self:GetIdFromPlayer(ply)

	if not id then
		return nil
	end

	local playerbuffer = nil

	if doNotCreate then
		playerbuffer = self.playerBufferManager:Get(id)
	else
		playerbuffer = self.playerBufferManager:CreateManagedObj(id, self.playerBufferClass, self, ply)
	end

	if not IsValid(playerbuffer) then
		return nil
	end

	return playerbuffer
end

function CLASS:GetIdFromPlayer(ply)
	if not self:IsValid() then
		return nil
	end

	if CLIENT then
		return "SERVER"
	end

	if isnumber(ply) or isstring(ply) then
		return tostring(ply)
	end

	if not IsValid(ply) then return nil end
	if not ply:IsPlayer() then return nil end
	if ply:IsBot() then return nil end

	local static = BASE
	static.playerIdCache = static.playerIdCache or {}

	if static.playerIdCache[ply] then
		return static.playerIdCache[ply]
	end

	static.playerIdCache[ply] = nil

	local playerid = string.format("%d | %s | %d", ply:EntIndex(), tostring(ply), ply:GetCreationID())

	local accountid = tostring(ply:AccountID() or "")
	if accountid ~= "" then
		playerid = string.format("%s | %s", playerid, accountid)
	end

	playerid = libTable:Hash(playerid)

	local cache = {}
	cache[ply] = playerid

	for k, v in pairs(static.playerIdCache) do
		if not IsValid(k) then continue end
		if not k:IsPlayer() then continue end
		if k:IsBot() then continue end

		cache[k] = v
	end

	static.playerIdCache = cache
	playerid = static.playerIdCache[ply]

	return playerid
end

function CLASS:GetPlayersFromTable(players)
	if not self:IsValid() then
		return nil
	end

	if CLIENT then
		return {NULL}
	end

	if not istable(players) then
		players = {players}
	end

	local plys = {}

	for k, ply in pairs(players) do
		local playerid = self:GetIdFromPlayer(ply)
		if not playerid then continue end

		plys[#plys + 1] = ply
	end

	return plys
end

function CLASS:Input(playerbuffer, ...)
	-- override me
end

function CLASS:Output(playerbuffer, ...)
	-- override me
end


return CLASS
