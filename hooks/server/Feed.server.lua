-- made by @mcs.s on discord

local Players = game:GetService("Players")
local SC = game:GetService("ScriptContext")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Fmt = require(Bits:WaitForChild("Fmt"))
local Rank = require(Bits:WaitForChild("Rank"))
local Hook = require(script.Parent.Hook)
local Store = require(SSS:WaitForChild("Data"):WaitForChild("Store"))

local seen: { [string]: number } = {}
local burnt = 0

task.spawn(function()
	local card = Hook.card("server up", Hook.hue.good)
		:row("place", game.PlaceId)
		:row("version", game.PlaceVersion)
		:row("private", game.PrivateServerId ~= "")
	Hook.send("main", card)
end)

Players.PlayerAdded:Connect(function(plr)
	local rank = Rank.wait(plr, 6)
	local d = Store.wait(plr, 12)
	local card = Hook.card("join", if rank == "player" then Hook.hue.dim else Hook.hue.info)
		:who(plr)
		:row("rank", rank)
		:row("age", plr.AccountAge .. "d")
		:row("visits", if d then d.visits else "?")
		:row("played", if d then Fmt.dur(d.secs) else "?")
		:row("here", #Players:GetPlayers())
	Hook.send("main", card)
end)

Players.PlayerRemoving:Connect(function(plr)
	local d = Store.get(plr)
	local card = Hook.card("leave", Hook.hue.dim)
		:who(plr)
		:row("played", if d then Fmt.dur(d.secs) else "?")
		:row("here", math.max(0, #Players:GetPlayers() - 1))
	Hook.send("main", card)
end)

SC.Error:Connect(function(msg, trace, from)
	local now = os.clock()
	if seen[msg] and now - seen[msg] < 30 then
		return
	end
	seen[msg] = now
	burnt += 1
	if burnt > 15 then
		return
	end
	local card = Hook.card("error", Hook.hue.bad)
		:txt(string.format("```\n%s\n%s\n```", Fmt.cut(msg, 400), Fmt.cut(trace, 1200)))
		:row("script", if from then from:GetFullName() else "unknown")
	Hook.send("err", card)
end)

task.spawn(function()
	while task.wait(60) do
		burnt = math.max(0, burnt - 5)
		for msg, at in seen do
			if os.clock() - at > 120 then
				seen[msg] = nil
			end
		end
	end
end)
