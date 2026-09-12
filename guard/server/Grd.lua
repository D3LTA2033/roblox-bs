-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Cfg = require(RepS:WaitForChild("Bits"):WaitForChild("Cfg"))

local Grd = {}

local pails: { [Player]: { [string]: { n: number, at: number } } } = {}

function Grd.ok(plr: Player, key: string, burst: number?, span: number?): boolean
	local cap = burst or Cfg.gate.burst
	local over = span or Cfg.gate.span
	local mine = pails[plr]
	if not mine then
		mine = {}
		pails[plr] = mine
	end
	local now = os.clock()
	local cell = mine[key]
	if not cell then
		mine[key] = { n = 1, at = now }
		return true
	end
	cell.n = math.max(0, cell.n - (now - cell.at) * (cap / over))
	cell.at = now
	if cell.n + 1 > cap then
		return false
	end
	cell.n += 1
	return true
end

function Grd.str(val: any, max: number): string?
	if type(val) ~= "string" then
		return nil
	end
	if #val == 0 or #val > max then
		return nil
	end
	if string.find(val, "%z") then
		return nil
	end
	return val
end

function Grd.int(val: any, low: number, high: number): number?
	if type(val) ~= "number" or val ~= val or val == math.huge or val == -math.huge then
		return nil
	end
	local n = math.floor(val)
	if n < low or n > high then
		return nil
	end
	return n
end

function Grd.bool(val: any): boolean
	return val == true
end

function Grd.near(plr: Player, spot: Vector3, max: number): boolean
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - spot).Magnitude <= max
end

function Grd.hook(rem: RemoteEvent, key: string, burst: number?, span: number?, fn: (Player, ...any) -> ())
	rem.OnServerEvent:Connect(function(plr, ...)
		if not Grd.ok(plr, key, burst, span) then
			return
		end
		local ok, err = pcall(fn, plr, ...)
		if not ok then
			warn(string.format("[grd] %s blew up: %s", key, tostring(err)))
		end
	end)
end

Players.PlayerRemoving:Connect(function(plr)
	pails[plr] = nil
end)

return Grd
