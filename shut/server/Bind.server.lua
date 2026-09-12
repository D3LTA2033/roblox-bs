-- made by @mcs.s on discord

local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local TPS = game:GetService("TeleportService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Go = require(script.Parent.Go)

if not Cfg.soft.on then
	return
end

local function sent(plr: Player): boolean
	local ok, data = pcall(function()
		return plr:GetJoinData().TeleportData
	end)
	return ok and type(data) == "table" and data.bounce == true
end

local function back(plr: Player, tries: number?)
	local max = tries or 4
	for i = 1, max do
		local ok = pcall(TPS.TeleportAsync, TPS, game.PlaceId, { plr })
		if ok then
			return
		end
		task.wait(i * 2)
		if plr.Parent == nil then
			return
		end
	end
	if plr.Parent then
		plr:Kick("could not move you to a new server, rejoin please")
	end
end

if game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0 then
	Players.PlayerAdded:Connect(function(plr)
		if sent(plr) then
			task.spawn(back, plr)
		end
	end)
	for _, plr in Players:GetPlayers() do
		if sent(plr) then
			task.spawn(back, plr)
		end
	end
end

TPS.TeleportInitFailed:Connect(function(plr, reason, why)
	warn(string.format("[soft] teleport failed for %s: %s %s", plr.Name, tostring(reason), tostring(why)))
	if plr.Parent then
		task.delay(2, back, plr, 2)
	end
end)

game:BindToClose(function()
	if Run:IsStudio() then
		return
	end
	Go.hold()
end)
