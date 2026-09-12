-- made by @mcs.s on discord

local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Rank = require(Bits:WaitForChild("Rank"))

local Gift = {}

local function hum(plr: Player): Humanoid?
	local char = plr.Character
	local got = char and char:FindFirstChildOfClass("Humanoid")
	if got and got.Health > 0 then
		return got
	end
	return nil
end

local function speed(plr: Player, n: number)
	if (plr:GetAttribute("Spd") or Cfg.ac.spd) >= n then
		return
	end
	plr:SetAttribute("Spd", n)
	local h = hum(plr)
	if h then
		h.WalkSpeed = n
	end
end

local acts: { [string]: (Player) -> () } = {}

acts.boots = function(plr)
	speed(plr, 24)
end

acts.legs = function(plr)
	plr:SetAttribute("Jmp", 75)
	plr:SetAttribute("Hgt", 75 / 7)
	local h = hum(plr)
	if h then
		if h.UseJumpPower then
			h.JumpPower = 75
		else
			h.JumpHeight = 75 / 7
		end
	end
end

acts.skin = function(plr)
	plr:SetAttribute("Hp", 150)
	local h = hum(plr)
	if h then
		h.MaxHealth = 150
		h.Health = 150
	end
end

acts.kit = function(plr)
	local h = hum(plr)
	if h then
		h.Health = h.MaxHealth
	end
end

acts.vip = function(plr)
	plr:SetAttribute("Mult", 2)
	speed(plr, 22)
	if Rank.lvl(plr) < Rank.need("vip") then
		plr:SetAttribute(Rank.key, "vip")
	end
end

acts.glow = function(plr)
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("Glow") then
		return
	end
	local lamp = Instance.new("PointLight")
	lamp.Name = "Glow"
	lamp.Brightness = 2
	lamp.Range = 18
	lamp.Color = Color3.fromRGB(255, 214, 130)
	lamp.Parent = root
end

acts.revive = function(plr)
	local h = hum(plr)
	if h then
		h.Health = h.MaxHealth
	else
		plr:LoadCharacter()
	end
end

function Gift.has(key: string): boolean
	return acts[key] ~= nil
end

function Gift.give(plr: Player, key: string): boolean
	local fn = acts[key]
	if not fn then
		return false
	end
	local ok, err = pcall(fn, plr)
	if not ok then
		warn(string.format("[gift] %s broke: %s", key, tostring(err)))
	end
	return ok
end

return Gift
