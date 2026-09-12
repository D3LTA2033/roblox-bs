-- made by @mcs.s on discord

local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Bin = require(Bits:WaitForChild("Bin"))
local Net = require(Bits:WaitForChild("Net"))
local Rank = require(Bits:WaitForChild("Rank"))
local Checks = require(script.Parent.Checks)
local Pen = require(script.Parent.Pen)
local Grd = require(SSS:WaitForChild("Gate"):WaitForChild("Grd"))

if not Cfg.ac.on then
	return
end

local beat = Net.ev("ac")
local pool = {}

local bad = {}
for _, name in Cfg.ac.bad do
	bad[name] = true
end

local function skip(plr: Player): boolean
	return Rank.at(plr, Cfg.ac.skipAt) or plr:GetAttribute("AcOff") == true
end

local function dress(plr: Player, char: Model)
	local st = pool[plr]
	if not st then
		return
	end
	st.bin:wipe()
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local root = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hum or not root or char.Parent == nil then
		return
	end
	st.char, st.hum, st.root = char, hum, root
	st.born = root.Size
	st.last, st.clipAt = root.Position, root.Position
	st.air, st.thru = 0, 0
	st.grace = os.clock() + Cfg.ac.grace
	st.bin:add(char.DescendantAdded:Connect(function(thing)
		if not bad[thing.ClassName] or thing:GetAttribute("Ok") == true then
			return
		end
		if skip(plr) or Checks.warped(plr) then
			return
		end
		local name = thing.ClassName
		thing:Destroy()
		Pen.hit(plr, "mover " .. name, 3)
	end))
	st.bin:add(hum.Died:Connect(function()
		st.grace = os.clock() + Cfg.ac.grace
	end))
	for _, thing in char:GetDescendants() do
		if bad[thing.ClassName] and thing:GetAttribute("Ok") ~= true then
			thing:Destroy()
		end
	end
end

local function add(plr: Player)
	pool[plr] = {
		plr = plr,
		bin = Bin.new(),
		grace = os.clock() + Cfg.ac.grace + 4,
		air = 0,
		thru = 0,
		beat = os.clock() + 20,
		born = Vector3.zero,
	}
	plr.CharacterAdded:Connect(function(char)
		dress(plr, char)
	end)
	if plr.Character then
		task.spawn(dress, plr, plr.Character)
	end
end

local function gone(plr: Player)
	local st = pool[plr]
	if st then
		st.bin:wipe()
	end
	pool[plr] = nil
end

Players.PlayerAdded:Connect(add)
Players.PlayerRemoving:Connect(gone)

for _, plr in Players:GetPlayers() do
	add(plr)
end

Grd.hook(beat, "ac", 6, 5, function(plr)
	local st = pool[plr]
	if st then
		st.beat = os.clock()
	end
end)

local pile = 0
Run.Heartbeat:Connect(function(dt)
	pile += dt
	if pile < Cfg.ac.step then
		return
	end
	local span = pile
	pile = 0
	for plr, st in pool do
		if plr.Parent == nil then
			continue
		end
		if skip(plr) then
			st.last = nil
			st.clipAt = nil
			continue
		end
		if st.root and st.root.Parent then
			local why = Checks.run(st, span)
			if why then
				Pen.hit(plr, why)
			end
		end
		if Cfg.ac.gap > 0 and os.clock() - st.beat > Cfg.ac.gap then
			st.beat = os.clock() + 30
			Pen.hit(plr, "client went quiet", 2)
		end
	end
end)
