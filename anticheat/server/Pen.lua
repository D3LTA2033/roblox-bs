-- made by @mcs.s on discord

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))
local Rank = require(Bits:WaitForChild("Rank"))
local Hook = require(SSS:WaitForChild("Hooks"):WaitForChild("Hook"))

local Pen = {}

local cards: { [Player]: { n: number, at: number, last: string, said: number } } = {}
local wire = Net.ev("adm")

local function card(plr: Player)
	local got = cards[plr]
	if not got then
		got = { n = 0, at = os.clock(), last = "", said = 0 }
		cards[plr] = got
	end
	return got
end

local function tell(line: string)
	for _, plr in Players:GetPlayers() do
		if Rank.at(plr, Cfg.adm.needAt) then
			wire:FireClient(plr, "out", line)
		end
	end
end

function Pen.count(plr: Player): number
	local got = cards[plr]
	if not got then
		return 0
	end
	local gone = os.clock() - got.at
	return math.max(0, got.n - math.floor(gone / Cfg.ac.decay))
end

function Pen.hit(plr: Player, why: string, weight: number?)
	if not plr.Parent then
		return
	end
	local got = card(plr)
	got.n = Pen.count(plr) + (weight or 1)
	got.at = os.clock()
	local spot = Vector3.zero
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		spot = root.Position
	end
	if got.last ~= why or os.clock() - got.said > 5 then
		got.last = why
		got.said = os.clock()
		tell(string.format("[ac] %s -> %s (%d/%d)", plr.Name, why, got.n, Cfg.ac.cap))
		Hook.send("ac", Hook.card("flag: " .. why, if got.n >= Cfg.ac.cap then Hook.hue.bad else Hook.hue.warn)
			:who(plr)
			:row("flags", string.format("%d/%d", got.n, Cfg.ac.cap))
			:row("ping", string.format("%dms", plr:GetNetworkPing() * 1000 // 1))
			:at(spot))
	end
	if got.n < Cfg.ac.cap then
		return
	end
	cards[plr] = nil
	local line = string.format(Cfg.ac.why, why)
	if Cfg.ac.ban then
		local ok, Bans = pcall(function()
			return require(SSS:WaitForChild("Adm"):WaitForChild("Bans"))
		end)
		if ok then
			Bans.add(plr.UserId, plr.Name, line, -1, "anti cheat")
		end
	end
	plr:Kick(line)
	tell(string.format("[ac] booted %s (%s)", plr.Name, why))
end

function Pen.clear(plr: Player)
	cards[plr] = nil
end

Players.PlayerRemoving:Connect(Pen.clear)

return Pen
