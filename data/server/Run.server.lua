-- made by @mcs.s on discord

local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Store = require(script.Parent.Store)
local Hook = require(SSS:WaitForChild("Hooks"):WaitForChild("Hook"))

local clocks: { [Player]: number } = {}

local function sync(plr: Player)
	local d = Store.get(plr)
	local started = clocks[plr]
	if not d or not started then
		return
	end
	d.secs += math.floor(os.clock() - started)
	clocks[plr] = os.clock()
end

local function join(plr: Player)
	clocks[plr] = os.clock()
	local d = Store.load(plr)
	if not d then
		if plr.Parent then
			plr:Kick("could not load your save, rejoin in a few seconds")
		end
		clocks[plr] = nil
		return
	end
	d.visits += 1
	d.seen = os.time()
	if d.made == 0 then
		d.made = os.time()
	end
	plr:SetAttribute("Visits", d.visits)
	plr:SetAttribute("Cash", d.cash)
end

local function bye(plr: Player)
	sync(plr)
	clocks[plr] = nil
	Store.save(plr, true)
end

Players.PlayerAdded:Connect(join)
Players.PlayerRemoving:Connect(bye)

for _, plr in Players:GetPlayers() do
	task.spawn(join, plr)
end

task.spawn(function()
	while task.wait(Cfg.data.auto) do
		for plr in Store.all() do
			if plr.Parent then
				sync(plr)
				Store.save(plr, false)
				task.wait(0.6)
			end
		end
	end
end)

game:BindToClose(function()
	if Run:IsStudio() then
		return
	end
	for plr in Store.all() do
		sync(plr)
	end
	Hook.now("main", "server closing, flushing " .. tostring(#Players:GetPlayers()) .. " saves")
	Store.flush()
end)
