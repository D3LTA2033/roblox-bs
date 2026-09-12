-- made by @mcs.s on discord

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))
local Rank = require(Bits:WaitForChild("Rank"))
local Store = require(SSS:WaitForChild("Data"):WaitForChild("Store"))

if not Cfg.greet.on then
	return
end

local pipe = Net.ev("greet")

local function sheet(plr: Player, rank: string)
	local d = Store.get(plr)
	return {
		id = plr.UserId,
		name = plr.DisplayName,
		at = plr.Name,
		rank = rank,
		visits = if d then d.visits else 1,
		secs = if d then d.secs else 0,
		new = if d then d.visits <= 1 else true,
	}
end

local function tell(plr: Player)
	local rank = Rank.wait(plr, 6)
	Store.wait(plr, 12)
	if plr.Parent == nil then
		return
	end
	local card = sheet(plr, rank)
	pipe:FireAllClients(card)
	for _, other in Players:GetPlayers() do
		if other ~= plr then
			pipe:FireClient(plr, sheet(other, Rank.of(other)))
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(tell, plr)
end)

for _, plr in Players:GetPlayers() do
	task.spawn(tell, plr)
end
