-- made by @mcs.s on discord

local RepS = game:GetService("ReplicatedStorage")

local Cfg = require(RepS:WaitForChild("Bits"):WaitForChild("Cfg"))

local Checks = {}

local air = Enum.Material.Air
local water = Enum.Material.Water

local loose = {
	[Enum.HumanoidStateType.Swimming] = true,
	[Enum.HumanoidStateType.Climbing] = true,
	[Enum.HumanoidStateType.Flying] = true,
	[Enum.HumanoidStateType.Physics] = true,
	[Enum.HumanoidStateType.Dead] = true,
	[Enum.HumanoidStateType.Ragdoll] = true,
	[Enum.HumanoidStateType.FallingDown] = true,
	[Enum.HumanoidStateType.GettingUp] = true,
}

local beam = RaycastParams.new()
beam.FilterType = Enum.RaycastFilterType.Exclude
beam.IgnoreWater = true
beam.RespectCanCollide = true

function Checks.warped(plr: Player): boolean
	local at = plr:GetAttribute("Warp")
	if typeof(at) ~= "number" then
		return false
	end
	return workspace:GetServerTimeNow() - at < 2.5
end

function Checks.open(st): boolean
	local hum, root = st.hum, st.root
	if not hum or not root or root.Parent == nil then
		return false
	end
	if hum.Health <= 0 or os.clock() < st.grace then
		return false
	end
	if hum.Sit or hum.SeatPart or hum.PlatformStand then
		return false
	end
	if root.AssemblyRootPart ~= root then
		return false
	end
	if loose[hum:GetState()] then
		return false
	end
	return not Checks.warped(st.plr)
end

function Checks.move(st, span: number): string?
	local spot = st.root.Position
	local was = st.last
	st.last = spot
	if not was then
		return nil
	end
	local flat = (spot * Vector3.new(1, 0, 1) - was * Vector3.new(1, 0, 1)).Magnitude
	local lag = st.plr:GetNetworkPing() * 2 * Cfg.ac.ping
	local speed = (st.plr:GetAttribute("Spd") or Cfg.ac.spd) :: number
	local room = speed * (span + lag) * Cfg.ac.pad + 5
	if flat > room then
		return string.format("speed %d over %d", flat // 1, room // 1)
	end
	return nil
end

function Checks.fly(st, span: number): string?
	local hum, root = st.hum, st.root
	if hum.FloorMaterial ~= air then
		st.air = 0
		return nil
	end
	local drop = root.AssemblyLinearVelocity.Y
	if drop < Cfg.ac.fall then
		st.air = 0
		return nil
	end
	st.air += span
	if st.air < Cfg.ac.air then
		return nil
	end
	beam.FilterDescendantsInstances = { st.char }
	local under = workspace:Raycast(root.Position, Vector3.new(0, -Cfg.ac.floor, 0), beam)
	if under then
		st.air = 0
		return nil
	end
	st.air = 0
	return string.format("air %0.1fs at y %d", Cfg.ac.air, root.Position.Y // 1)
end

function Checks.clip(st): string?
	local was, spot = st.clipAt, st.root.Position
	st.clipAt = spot
	if not was then
		return nil
	end
	local step = spot - was
	if step.Magnitude < 3 then
		st.thru = 0
		return nil
	end
	beam.FilterDescendantsInstances = { st.char }
	local wall = workspace:Raycast(was, step, beam)
	if wall and wall.Instance.CanCollide and wall.Material ~= water then
		st.thru += 1
		if st.thru >= Cfg.ac.clip then
			st.thru = 0
			return "clipped " .. wall.Instance.Name
		end
		return nil
	end
	st.thru = 0
	return nil
end

function Checks.stat(st): string?
	local hum = st.hum
	local plr = st.plr
	local speed = (plr:GetAttribute("Spd") or Cfg.ac.spd) :: number
	if hum.WalkSpeed > speed + 0.6 then
		local bad = hum.WalkSpeed
		hum.WalkSpeed = speed
		return string.format("walkspeed %0.1f", bad)
	end
	if hum.UseJumpPower then
		local jump = (plr:GetAttribute("Jmp") or Cfg.ac.jmp) :: number
		if hum.JumpPower > jump + 0.6 then
			local bad = hum.JumpPower
			hum.JumpPower = jump
			return string.format("jumppower %0.1f", bad)
		end
	else
		local high = (plr:GetAttribute("Hgt") or Cfg.ac.hgt) :: number
		if hum.JumpHeight > high + 0.4 then
			local bad = hum.JumpHeight
			hum.JumpHeight = high
			return string.format("jumpheight %0.1f", bad)
		end
	end
	if not plr:GetAttribute("God") then
		local cap = (plr:GetAttribute("Hp") or Cfg.ac.hp) :: number
		if hum.MaxHealth > cap + 0.5 then
			return string.format("maxhealth %0.1f", hum.MaxHealth)
		end
	end
	if st.root.Size ~= st.born then
		return "root part resized"
	end
	return nil
end

function Checks.run(st, span: number): string?
	if not Checks.open(st) then
		st.last = st.root and st.root.Position or nil
		st.clipAt = st.last
		st.air = 0
		return nil
	end
	return Checks.stat(st) or Checks.move(st, span) or Checks.fly(st, span) or Checks.clip(st)
end

return Checks
