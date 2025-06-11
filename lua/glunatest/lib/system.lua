local LIB = {}

function LIB:IsDedicatedServer()
	return self:IsServer() and game.IsDedicated()
end

function LIB:IsListenServer()
	return self:IsServer() and not game.IsDedicated()
end

function LIB:IsWindows()
	return system.IsWindows()
end

function LIB:IsLinux()
	return system.IsLinux()
end

function LIB:IsServer()
	return SERVER
end

function LIB:IsClient()
	return CLIENT
end

function LIB:IsCLI()
	return self:IsDedicatedServer()
end

function LIB:IsWindowsCLI()
	return self:IsWindows() and self:IsCLI()
end

function LIB:IsLinuxCLI()
	return self:IsLinux() and self:IsCLI()
end

return LIB
