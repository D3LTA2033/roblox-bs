-- made by @mcs.s on discord

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Net = require(Bits:WaitForChild("Net"))
local Grd = require(SSS:WaitForChild("Gate"):WaitForChild("Grd"))

if not Cfg.afk.on then
	return
end

local pipe = Net.ev("afk")
local since: { [Player]: number } = {}

Grd.hook(pipe, "afk", 6, 10, function(plr, on)
	local flag = Grd.bool(on)
	plr:SetAttribute("Afk", if flag then true else nil)
	since[plr] = if flag then os.clock() else nil
end)

Players.PlayerRemoving:Connect(function(plr)
	since[plr] = nil
end)

if Cfg.afk.boot > 0 then
	task.spawn(function()
		while task.wait(20) do
			local pile = {}
			for plr, at in since do
				if plr.Parent and os.clock() - at > Cfg.afk.boot then
					table.insert(pile, plr)
				end
			end
			for _, plr in pile do
				since[plr] = nil
				plr:Kick(string.format("away for %s, come back any time", Fmt.dur(Cfg.afk.boot)))
			end
		end
	end)
end
