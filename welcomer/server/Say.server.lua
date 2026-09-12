-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Net = require(Bits:WaitForChild("Net"))
local Rank = require(Bits:WaitForChild("Rank"))

if not Cfg.say.on then
	return
end

local pipe = Net.ev("say")

local function ring(plr: Player)
	local rank = Rank.wait(plr, 6)
	if plr.Parent == nil then
		return
	end
	local tier = Rank.tiers[rank]
	local name = Fmt.esc(plr.DisplayName)
	local text
	if tier.loud then
		text = string.format(Cfg.say.big, name, rank)
	elseif Cfg.say.all then
		text = string.format(Cfg.say.join, name)
	end
	if text then
		pipe:FireAllClients("join", text, tier.hue)
	end
	task.wait(1.5)
	if plr.Parent == nil then
		return
	end
	for _, line in Cfg.say.motd do
		pipe:FireClient(plr, "motd", line)
		task.wait(0.6)
	end
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(ring, plr)
end)

Players.PlayerRemoving:Connect(function(plr)
	if not Cfg.say.left then
		return
	end
	pipe:FireAllClients("left", string.format(Cfg.say.out, Fmt.esc(plr.DisplayName)), Rank.hue(plr))
end)

for _, plr in Players:GetPlayers() do
	task.spawn(ring, plr)
end
