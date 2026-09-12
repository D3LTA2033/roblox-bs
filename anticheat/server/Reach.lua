-- made by @mcs.s on discord

local RepS = game:GetService("ReplicatedStorage")

local Cfg = require(RepS:WaitForChild("Bits"):WaitForChild("Cfg"))
local Pen = require(script.Parent.Pen)

local Reach = {}

function Reach.ok(plr: Player, spot: Vector3, max: number?): boolean
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	local lag = plr:GetNetworkPing() * 2
	local speed = (plr:GetAttribute("Spd") or Cfg.ac.spd) :: number
	local room = (max or Cfg.ac.reach) + speed * math.min(lag, 0.5)
	local gap = (root.Position - spot).Magnitude
	if gap <= room then
		return true
	end
	Pen.hit(plr, string.format("reach %d over %d", gap // 1, room // 1), 2)
	return false
end

function Reach.hits(plr: Player, mark: Model, max: number?): boolean
	local root = mark and mark:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return Reach.ok(plr, root.Position, max)
end

return Reach
