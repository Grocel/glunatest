local glnet = GLunaTestLib.net
local glclass = GLunaTestLib.class
local lunatest = package.loaded.lunatest

local suite = {}

local data1_empty = glclass:CreateObj("stream")
local data1_small = glclass:CreateObj("stream")
local data1_big = glclass:CreateObj("stream")

for i = 0, 30 do
	data1_small:WriteUInt24(i)
end

data1_small:WriteString("some test string1")

for i = 0, 30000 do
	data1_big:WriteUInt24(i)
end

data1_big:WriteString("some test string2")

local data2_empty = glclass:CreateObj("stream", data1_empty)
local data2_small = glclass:CreateObj("stream", data1_small)
local data2_big = glclass:CreateObj("stream", data1_big)

function suite.suite_setup()
	local receiver, sender = glnet:GetLoopbackSetup()
	receiver:Remove()
	sender:Remove()
end

function suite.suite_teardown()
	local receiver, sender = glnet:GetLoopbackSetup()
	receiver:Remove()
	sender:Remove()
end

function suite.teardown()
	local receiver, sender = glnet:GetLoopbackSetup()
	receiver:Remove()
	sender:Remove()
end

local cases_oneplayer = {
	["1_nil"] = {nil, 0},
	["2_empty_string"] = {"", 0},
	["3_empty_stream"] = {data1_empty, 0},
	["4_string"] = {"some test string3", 17},
	["5_small"] = {data1_small, 113},
	["6_big"] = {data1_big, 90023},
}

local cases_allplayers = {
	["1_nil"] = {nil, 0},
	["2_empty_string"] = {"", 0},
	["3_empty_stream"] = {data2_empty, 0},
	["4_string"] = {"some test string3", 17},
	["5_small"] = {data2_small, 113},
	["6_big"] = {data2_big, 90023},
}

lunatest.add_tests_by_table(suite, "transmission_oneplayer", cases_oneplayer, function(key, data, index)
	local ply = lunatest.getPlayer()

	if not IsValid(ply) then
		lunatest.skip("This test needs atleast one connected player.")
		return
	end

	local receiver, sender = glnet:GetLoopbackSetup()
	local playerTestString = tostring(ply)

	local size = data[2]
	data = data[1]

	if data then
		data = data .. playerTestString
		size = size + #playerTestString
	end

	local OnReceive = lunatest.async(function(this, stream, thisply)
		lunatest.assert_equal(receiver, this)

		if SERVER then
			lunatest.assert_equal(ply, thisply)
		else
			lunatest.assert_nil(thisplys)
		end

		lunatest.assert_equal_bytes(tostring(data or ""), tostring(stream))
		lunatest.assert_equal(size, stream:GetSize())
	end)

	local OnProgressReceiver = lunatest.async(function(this, data, thisply)
		lunatest.assert_equal(receiver, this)

		if SERVER then
			lunatest.assert_equal(ply, thisply)
		else
			lunatest.assert_nil(thisplys)
		end

		return true
	end)

	local OnProgressSender = lunatest.async(function(this, data, thisply)
		lunatest.assert_equal(sender, this)

		if SERVER then
			lunatest.assert_equal(ply, thisply)
		else
			lunatest.assert_nil(thisplys)
		end

		return true
	end)

	local OnDoneReceiver = lunatest.async(function(this, thisply)
		lunatest.assert_equal(receiver, this)

		if SERVER then
			lunatest.assert_equal(ply, thisply)
		else
			lunatest.assert_nil(thisplys)
		end
	end)

	local OnDoneSender = lunatest.async(function(this, thisply)
		lunatest.assert_equal(sender, this)

		if SERVER then
			lunatest.assert_equal(ply, thisply)
		else
			lunatest.assert_nil(thisplys)
		end
	end)

	local OnTransmitted = lunatest.async(function(this, thisply)
		lunatest.assert_equal(sender, this)

		if SERVER then
			lunatest.assert_equal(ply, thisply)
		else
			lunatest.assert_nil(thisplys)
		end
	end)

	local OnErrorSender = lunatest.async(function(this, status, statusname, thisply)
		lunatest.fail(tostring(this) .. ": " .. statusname .. " at " .. tostring(thisply), true)
	end)

	local OnCancelSender = lunatest.async(function(this, thisply)
		lunatest.fail(tostring(this) .. ": Canceled by " .. tostring(thisply), true)
	end)

	local OnTimeoutSender = lunatest.async(function(this, thisply)
		lunatest.fail(tostring(this) .. ": Timeout at " .. tostring(thisply), true)
	end)

	local OnErrorReceiver = lunatest.async(function(this, status, statusname, thisply)
		lunatest.fail(tostring(this) .. ": " .. statusname .. " at " .. tostring(thisply), true)
	end)

	local OnCancelReceiver = lunatest.async(function(this, thisply)
		lunatest.fail(tostring(this) .. ": Canceled by " .. tostring(thisply), true)
	end)

	local OnTimeoutReceiver = lunatest.async(function(this, thisply)
		lunatest.fail(tostring(this) .. ": Timeout at " .. tostring(thisply), true)
	end)

	local OnSend = lunatest.async(function(this, stream, thisplys)
		lunatest.assert_equal(sender, this)

		if SERVER then
			lunatest.assert_equal_ex({ply}, thisplys)
		else
			lunatest.assert_nil(thisplys)
		end

		lunatest.assert_equal_bytes(tostring(data or ""), tostring(stream))
		lunatest.assert_equal(size, stream:GetSize())
	end)

	receiver.OnReceive = -OnReceive
	receiver.OnProgress = -OnProgressReceiver

	receiver.OnError = -OnErrorReceiver
	receiver.OnCancel = -OnCancelReceiver
	receiver.OnTimeout = -OnTimeoutReceiver
	receiver.OnDone = -OnDoneReceiver

	sender.OnProgress = -OnProgressSender
	sender.OnTransmitted = -OnTransmitted
	sender.OnDone = -OnDoneSender
	sender.OnSend = -OnSend

	sender.OnError = -OnErrorSender
	sender.OnCancel = -OnCancelSender
	sender.OnTimeout = -OnTimeoutSender

	sender:Send(ply, data)

	OnSend:Sync(0.1)

	OnDoneSender:Sync(30)

	OnProgressSender:SyncOptional(0.1)
	OnTimeoutSender:SyncOptional(0.1)
	OnErrorSender:SyncOptional(0.1)
	OnCancelSender:SyncOptional(0.1)

	OnDoneReceiver:Sync(30)

	OnProgressReceiver:SyncOptional(0.1)
	OnTimeoutReceiver:SyncOptional(0.1)
	OnErrorReceiver:SyncOptional(0.1)
	OnCancelReceiver:SyncOptional(0.1)
end)

if SERVER then
	lunatest.add_tests_by_table(suite, "transmission_allplayers", cases_allplayers, function(key, data, index)
		local plys = {unpack(player.GetHumans(), 1, 4)}

		local check = {}

		for i, v in ipairs(plys) do
			check[v] = {
				OnReceive = true,
				OnProgressReceiver = true,
				OnProgressSender = true,
				OnDoneReceiver = true,
				OnDoneSender = true,
				OnTransmitted = true,
			}
		end

		local plycount = #plys

		if plycount < 2 then
			lunatest.skip("This test needs atleast two connected players.")
			return
		end

		local receiver, sender = glnet:GetLoopbackSetup()

		local playersTestString = tostring(plys)

		local size = data[2]
		data = data[1]

		if data then
			data = data .. playersTestString
			size = size + #playersTestString
		end

		local OnReceive = lunatest.async(function(this, stream, thisply)
			lunatest.assert_equal(receiver, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnReceive)

			thischeck.OnReceive = nil

			lunatest.assert_equal_bytes(tostring(data or ""), tostring(stream))
			lunatest.assert_equal(size, stream:GetSize())
		end)

		local OnProgressReceiver = lunatest.async(function(this, data, thisply)
			lunatest.assert_equal(receiver, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)

			thischeck.OnProgressReceiver = nil

			return true
		end)

		local OnProgressSender = lunatest.async(function(this, data, thisply)
			lunatest.assert_equal(sender, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)

			thischeck.OnProgressSender = nil

			return true
		end)

		local OnDoneReceiver = lunatest.async(function(this, thisply)
			lunatest.assert_equal(receiver, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnDoneReceiver)

			thischeck.OnDoneReceiver = nil
		end)

		local OnDoneSender = lunatest.async(function(this, thisply)
			lunatest.assert_equal(sender, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnDoneSender)

			thischeck.OnDoneSender = nil
		end)

		local OnTransmitted = lunatest.async(function(this, thisply)
			lunatest.assert_equal(sender, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnTransmitted)

			thischeck.OnTransmitted = nil
		end)

		local OnErrorSender = lunatest.async(function(this, status, statusname, thisply)
			lunatest.fail(tostring(this) .. ": " .. statusname .. " at " .. tostring(thisply), true)
		end)

		local OnCancelSender = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Canceled by " .. tostring(thisply), true)
		end)

		local OnTimeoutSender = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Timeout at " .. tostring(thisply), true)
		end)

		local OnErrorReceiver = lunatest.async(function(this, status, statusname, thisply)
			lunatest.fail(tostring(this) .. ": " .. statusname .. " at " .. tostring(thisply), true)
		end)

		local OnCancelReceiver = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Canceled by " .. tostring(thisply), true)
		end)

		local OnTimeoutReceiver = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Timeout at " .. tostring(thisply), true)
		end)

		local OnSend = lunatest.async(function(this, stream, thisplys)
			lunatest.assert_equal(sender, this)
			lunatest.assert_equal_ex(plys, thisplys)

			lunatest.assert_equal_bytes(tostring(data or ""), tostring(stream))
			lunatest.assert_equal(size, stream:GetSize())
		end)

		receiver.OnReceive = -OnReceive
		receiver.OnProgress = -OnProgressReceiver

		receiver.OnError = -OnErrorReceiver
		receiver.OnCancel = -OnCancelReceiver
		receiver.OnTimeout = -OnTimeoutReceiver
		receiver.OnDone = -OnDoneReceiver

		sender.OnProgress = -OnProgressSender
		sender.OnTransmitted = -OnTransmitted
		sender.OnDone = -OnDoneSender
		sender.OnSend = -OnSend

		sender.OnError = -OnErrorSender
		sender.OnCancel = -OnCancelSender
		sender.OnTimeout = -OnTimeoutSender

		sender:Send(ply, data)

		OnSend:Sync(0.1)

		OnDoneSender:Sync(30 * plycount, plycount)

		OnProgressSender:SyncOptional(0.1)
		OnTimeoutSender:SyncOptional(0.1)
		OnErrorSender:SyncOptional(0.1)
		OnCancelSender:SyncOptional(0.1)

		OnDoneReceiver:Sync(30 * plycount, plycount)

		OnProgressReceiver:SyncOptional(0.1)
		OnTimeoutReceiver:SyncOptional(0.1)
		OnErrorReceiver:SyncOptional(0.1)
		OnCancelReceiver:SyncOptional(0.1)

		for k, v in pairs(check) do
			lunatest.assert_equal(0, table.Count(v), "Not all players have been completely supplied!")
		end
	end)

	function suite.test_transmission_per_player_data()
		local plys = {unpack(player.GetHumans(), 1, 4)}

		local check = {}

		local function getDataForPlayer(p)
			return string.rep(tostring(p), 5000, " /// ")
		end

		for i, v in ipairs(plys) do
			local data = getDataForPlayer(v)
			local size = #data

			check[v] = {
				OnReceive = {data, size},
				OnProgressReceiver = true,
				OnProgressSender = true,
				OnTransmitted = true,
				OnDoneReceiver = true,
				OnDoneSender = true,
				OnSend = {data, size},
			}
		end

		local plycount = #plys

		if plycount < 2 then
			lunatest.skip("This test needs atleast two connected players.")
			return
		end

		local receiver, sender = glnet:GetLoopbackSetup()

		local OnReceive = lunatest.async(function(this, stream, thisply)
			lunatest.assert_equal(receiver, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)

			local data = thischeck.OnReceive[1]
			local size = thischeck.OnReceive[2]

			thischeck.OnReceive = nil

			lunatest.assert_equal_bytes(tostring(data or ""), tostring(stream))
			lunatest.assert_equal(size, stream:GetSize())
		end)

		local OnProgressReceiver = lunatest.async(function(this, data, thisply)
			lunatest.assert_equal(receiver, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)

			thischeck.OnProgressReceiver = nil
			return true
		end)

		local OnProgressSender = lunatest.async(function(this, data, thisply)
			lunatest.assert_equal(sender, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)

			thischeck.OnProgressSender = nil
			return true
		end)

		local OnDoneReceiver = lunatest.async(function(this, thisply)
			lunatest.assert_equal(receiver, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnDoneReceiver)

			thischeck.OnDoneReceiver = nil
		end)

		local OnDoneSender = lunatest.async(function(this, thisply)
			lunatest.assert_equal(sender, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnDoneSender)

			thischeck.OnDoneSender = nil
		end)

		local OnTransmitted = lunatest.async(function(this, thisply)
			lunatest.assert_equal(sender, this)
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnTransmitted)

			thischeck.OnTransmitted = nil
		end)

		local OnErrorSender = lunatest.async(function(this, status, statusname, thisply)
			lunatest.fail(tostring(this) .. ": " .. statusname .. " at " .. tostring(thisply), true)
		end)

		local OnCancelSender = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Canceled by " .. tostring(thisply), true)
		end)

		local OnTimeoutSender = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Timeout at " .. tostring(thisply), true)
		end)

		local OnErrorReceiver = lunatest.async(function(this, status, statusname, thisply)
			lunatest.fail(tostring(this) .. ": " .. statusname .. " at " .. tostring(thisply), true)
		end)

		local OnCancelReceiver = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Canceled by " .. tostring(thisply), true)
		end)

		local OnTimeoutReceiver = lunatest.async(function(this, thisply)
			lunatest.fail(tostring(this) .. ": Timeout at " .. tostring(thisply), true)
		end)

		local OnSend = lunatest.async(function(this, stream, thisplys)
			lunatest.assert_equal(sender, this)

			local thisply = thisplys[1]
			lunatest.assert_valid(thisply)

			local thischeck = check[thisply]
			lunatest.assert_not_nil(thischeck)
			lunatest.assert_not_nil(thischeck.OnSend)

			local data = thischeck.OnSend[1]
			local size = thischeck.OnSend[2]

			thischeck.OnSend = nil

			lunatest.assert_equal_bytes(tostring(data or ""), tostring(stream))
			lunatest.assert_equal(size, stream:GetSize())
		end)

		receiver.OnReceive = -OnReceive
		receiver.OnProgress = -OnProgressReceiver

		receiver.OnError = -OnErrorReceiver
		receiver.OnCancel = -OnCancelReceiver
		receiver.OnTimeout = -OnTimeoutReceiver
		receiver.OnDone = -OnDoneReceiver

		sender.OnProgress = -OnProgressSender
		sender.OnTransmitted = -OnTransmitted
		sender.OnDone = -OnDoneSender
		sender.OnSend = -OnSend

		sender.OnError = -OnErrorSender
		sender.OnCancel = -OnCancelSender
		sender.OnTimeout = -OnTimeoutSender

		for i, v in ipairs(plys) do
			local data = getDataForPlayer(v)
			sender:Send(v, data)
		end

		OnSend:Sync(0.1)

		OnDoneSender:Sync(30 * plycount, plycount)

		OnProgressSender:SyncOptional(0.1)
		OnTimeoutSender:SyncOptional(0.1)
		OnErrorSender:SyncOptional(0.1)
		OnCancelSender:SyncOptional(0.1)

		OnDoneReceiver:Sync(30 * plycount, plycount)

		OnProgressReceiver:SyncOptional(0.1)
		OnTimeoutReceiver:SyncOptional(0.1)
		OnErrorReceiver:SyncOptional(0.1)
		OnCancelReceiver:SyncOptional(0.1)

		for k, v in pairs(check) do
			lunatest.assert_equal(0, table.Count(v), "Not all players have been completely supplied!")
		end
	end
end

return suite
