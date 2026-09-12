-- made by @mcs.s on discord

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local SS = game:GetService("ServerStorage")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Net = require(Bits:WaitForChild("Net"))
local Rank = require(Bits:WaitForChild("Rank"))
local Args = require(script.Parent.Args)
local Bans = require(script.Parent.Bans)
local Mute = require(script.Parent.Mute)
local Store = require(SSS:WaitForChild("Data"):WaitForChild("Store"))

local Cmds = {}

Cmds.list = {}
Cmds.by = {}

local say = Net.ev("say")
local ghosts: { [Player]: { [Instance]: number } } = {}
local born = os.time()

local function add(def)
	table.insert(Cmds.list, def)
	Cmds.by[def.name] = def
	for _, a in def.alias or {} do
		Cmds.by[a] = def
	end
end

local function hum(plr: Player): Humanoid?
	local char = plr.Character
	local got = char and char:FindFirstChildOfClass("Humanoid")
	if got and got.Health > 0 then
		return got
	end
	return nil
end

local function root(plr: Player): BasePart?
	local char = plr.Character
	local got = char and char:FindFirstChild("HumanoidRootPart")
	if got and got:IsA("BasePart") then
		return got
	end
	return nil
end

local function warp(plr: Player)
	plr:SetAttribute("Warp", workspace:GetServerTimeNow())
end

local function drop(plr: Player, spot: Vector3)
	local char = plr.Character
	if not char or not char.PrimaryPart then
		return false
	end
	warp(plr)
	char:PivotTo(CFrame.new(spot))
	return true
end

local function speed(plr: Player, n: number)
	plr:SetAttribute("Spd", n)
	local h = hum(plr)
	if h then
		h.WalkSpeed = n
	end
end

local function jump(plr: Player, n: number)
	local h = hum(plr)
	plr:SetAttribute("Jmp", n)
	plr:SetAttribute("Hgt", n / 7)
	if h then
		if h.UseJumpPower then
			h.JumpPower = n
		else
			h.JumpHeight = n / 7
		end
	end
end

add({
	name = "cmds",
	alias = { "help", "c" },
	need = "mod",
	use = ";cmds",
	run = function(ctx)
		local pile = {}
		for _, def in Cmds.list do
			if ctx.lvl >= Rank.need(def.need) then
				table.insert(pile, def.use)
			end
		end
		table.sort(pile)
		ctx.out(string.format("%d commands", #pile))
		for _, line in pile do
			ctx.out(line)
		end
	end,
})

add({
	name = "kick",
	alias = { "k" },
	need = "mod",
	use = ";kick <who> [why]",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local why = Args.rest(bits, 2, "no reason given")
		for _, plr in pile do
			if Rank.lvl(plr) >= ctx.lvl and plr ~= ctx.plr then
				ctx.out(plr.Name .. " outranks you")
				continue
			end
			plr:Kick(string.format("kicked by %s: %s", ctx.plr.Name, why))
		end
		return "kicked " .. Args.names(pile)
	end,
})

add({
	name = "ban",
	need = "admin",
	use = ";ban <who> <time|perm> [why]",
	run = function(ctx, bits)
		local id, name = Args.id(bits[1])
		if not id then
			return "no user called " .. tostring(bits[1])
		end
		local there = Players:GetPlayerByUserId(id)
		if there and Rank.lvl(there) >= ctx.lvl then
			return there.Name .. " outranks you"
		end
		local secs = Args.secs(bits[2])
		local why = Args.rest(bits, 3, "no reason given")
		local ok = Bans.add(id, name or tostring(id), why, secs, ctx.plr.Name)
		if not ok then
			return "ban did not save, check datastore access"
		end
		return string.format("banned %s for %s", name, if secs > 0 then Fmt.dur(secs) else "ever")
	end,
})

add({
	name = "unban",
	need = "admin",
	use = ";unban <who>",
	run = function(ctx, bits)
		local id, name = Args.id(bits[1])
		if not id then
			return "no user called " .. tostring(bits[1])
		end
		if Bans.drop(id) then
			return "unbanned " .. tostring(name)
		end
		return "could not unban " .. tostring(name)
	end,
})

add({
	name = "mute",
	need = "mod",
	use = ";mute <who> [time]",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local secs = Args.secs(bits[2])
		for _, plr in pile do
			if Rank.lvl(plr) < ctx.lvl or plr == ctx.plr then
				Mute.add(plr.UserId, secs, ctx.plr.Name)
			end
		end
		return string.format("muted %s for %s", Args.names(pile), if secs > 0 then Fmt.dur(secs) else "ever")
	end,
})

add({
	name = "unmute",
	need = "mod",
	use = ";unmute <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			Mute.drop(plr.UserId)
		end
		return "unmuted " .. Args.names(pile)
	end,
})

add({
	name = "kill",
	need = "mod",
	use = ";kill <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local h = hum(plr)
			if h then
				h.Health = 0
			end
		end
		return "killed " .. Args.names(pile)
	end,
})

add({
	name = "heal",
	alias = { "hl" },
	need = "mod",
	use = ";heal <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local h = hum(plr)
			if h then
				h.Health = h.MaxHealth
			end
		end
		return "healed " .. Args.names(pile)
	end,
})

add({
	name = "hp",
	need = "admin",
	use = ";hp <who> <n>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local n = Args.num(bits[2], 1, 100000, Cfg.ac.hp)
		for _, plr in pile do
			local h = hum(plr)
			plr:SetAttribute("Hp", n)
			if h then
				h.MaxHealth = n
				h.Health = n
			end
		end
		return string.format("set hp %d on %s", n, Args.names(pile))
	end,
})

add({
	name = "god",
	need = "admin",
	use = ";god <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			plr:SetAttribute("God", true)
			local h = hum(plr)
			if h then
				h.MaxHealth = math.huge
				h.Health = math.huge
			end
		end
		return Args.names(pile) .. " is unkillable"
	end,
})

add({
	name = "ungod",
	need = "admin",
	use = ";ungod <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			plr:SetAttribute("God", nil)
			local h = hum(plr)
			if h then
				h.MaxHealth = (plr:GetAttribute("Hp") or Cfg.ac.hp) :: number
				h.Health = h.MaxHealth
			end
		end
		return Args.names(pile) .. " is mortal again"
	end,
})

add({
	name = "speed",
	alias = { "ws" },
	need = "mod",
	use = ";speed <who> <n>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local n = Args.num(bits[2], 0, 500, Cfg.ac.spd)
		for _, plr in pile do
			speed(plr, n)
		end
		return string.format("speed %d on %s", n, Args.names(pile))
	end,
})

add({
	name = "jump",
	alias = { "jp" },
	need = "mod",
	use = ";jump <who> <n>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local n = Args.num(bits[2], 0, 500, Cfg.ac.jmp)
		for _, plr in pile do
			jump(plr, n)
		end
		return string.format("jump %d on %s", n, Args.names(pile))
	end,
})

add({
	name = "tp",
	need = "mod",
	use = ";tp <who> <to>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local mark = Args.plr(ctx, bits[2])
		local spot = mark and root(mark)
		if not spot then
			return "cannot find " .. tostring(bits[2])
		end
		for _, plr in pile do
			if plr ~= mark then
				drop(plr, spot.Position + Vector3.new(math.random(-3, 3), 3, math.random(-3, 3)))
			end
		end
		return string.format("sent %s to %s", Args.names(pile), mark.Name)
	end,
})

add({
	name = "bring",
	need = "mod",
	use = ";bring <who>",
	run = function(ctx, bits)
		local spot = root(ctx.plr)
		if not spot then
			return "you have no character"
		end
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			if plr ~= ctx.plr then
				drop(plr, spot.Position + spot.CFrame.LookVector * 4 + Vector3.new(0, 2, 0))
			end
		end
		return "brought " .. Args.names(pile)
	end,
})

add({
	name = "to",
	need = "mod",
	use = ";to <who>",
	run = function(ctx, bits)
		local mark = Args.plr(ctx, bits[1])
		local spot = mark and root(mark)
		if not spot then
			return "cannot find " .. tostring(bits[1])
		end
		drop(ctx.plr, spot.Position + spot.CFrame.LookVector * 4 + Vector3.new(0, 2, 0))
		return "went to " .. mark.Name
	end,
})

add({
	name = "respawn",
	alias = { "re" },
	need = "mod",
	use = ";respawn <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			warp(plr)
			plr:LoadCharacter()
		end
		return "respawned " .. Args.names(pile)
	end,
})

add({
	name = "freeze",
	alias = { "fr" },
	need = "mod",
	use = ";freeze <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local r = root(plr)
			speed(plr, 0)
			jump(plr, 0)
			plr:SetAttribute("Froze", true)
			if r then
				r.AssemblyLinearVelocity = Vector3.zero
				r.Anchored = true
			end
		end
		return "froze " .. Args.names(pile)
	end,
})

add({
	name = "thaw",
	alias = { "unfreeze" },
	need = "mod",
	use = ";thaw <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local r = root(plr)
			plr:SetAttribute("Froze", nil)
			speed(plr, Cfg.ac.spd)
			jump(plr, Cfg.ac.jmp)
			if r then
				r.Anchored = false
			end
		end
		return "thawed " .. Args.names(pile)
	end,
})

add({
	name = "invis",
	need = "admin",
	use = ";invis <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local char = plr.Character
			if not char then
				continue
			end
			local kept = ghosts[plr] or {}
			ghosts[plr] = kept
			for _, thing in char:GetDescendants() do
				if thing:IsA("BasePart") and thing.Transparency < 1 then
					kept[thing] = thing.Transparency
					thing.Transparency = 1
				elseif thing:IsA("Decal") or thing:IsA("Texture") then
					kept[thing] = thing.Transparency
					thing.Transparency = 1
				end
			end
		end
		return Args.names(pile) .. " is gone"
	end,
})

add({
	name = "vis",
	need = "admin",
	use = ";vis <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local kept = ghosts[plr]
			if not kept then
				continue
			end
			for thing, was in kept do
				if thing.Parent then
					(thing :: any).Transparency = was
				end
			end
			ghosts[plr] = nil
		end
		return Args.names(pile) .. " is back"
	end,
})

add({
	name = "sit",
	need = "mod",
	use = ";sit <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local h = hum(plr)
			if h then
				h.Sit = true
			end
		end
		return "sat " .. Args.names(pile)
	end,
})

add({
	name = "stun",
	need = "mod",
	use = ";stun <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local h = hum(plr)
			if h then
				h.PlatformStand = true
			end
		end
		return "stunned " .. Args.names(pile)
	end,
})

add({
	name = "unstun",
	need = "mod",
	use = ";unstun <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local h = hum(plr)
			if h then
				h.PlatformStand = false
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
		return "up again " .. Args.names(pile)
	end,
})

add({
	name = "fling",
	need = "admin",
	use = ";fling <who> [power]",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local power = Args.num(bits[2], 10, 500, 90)
		for _, plr in pile do
			local r = root(plr)
			if r then
				warp(plr)
				r.AssemblyLinearVelocity = Vector3.new(math.random(-power, power), power, math.random(-power, power))
			end
		end
		return "flung " .. Args.names(pile)
	end,
})

add({
	name = "give",
	need = "admin",
	use = ";give <who> <tool>",
	run = function(ctx, bits)
		local box = SS:FindFirstChild(Cfg.adm.toolBox)
		if not box then
			return "no " .. Cfg.adm.toolBox .. " folder in serverstorage"
		end
		local want = string.lower(Args.rest(bits, 2))
		local pick
		for _, thing in box:GetChildren() do
			if thing:IsA("Tool") and string.sub(string.lower(thing.Name), 1, #want) == want then
				pick = thing
				break
			end
		end
		if not pick then
			return "no tool like " .. want
		end
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			local bag = plr:FindFirstChildOfClass("Backpack")
			if bag then
				pick:Clone().Parent = bag
			end
		end
		return string.format("gave %s to %s", pick.Name, Args.names(pile))
	end,
})

add({
	name = "announce",
	alias = { "m" },
	need = "mod",
	use = ";announce <text>",
	run = function(ctx, bits)
		local text = Fmt.esc(Fmt.cut(Args.rest(bits, 1), Cfg.adm.cap))
		if text == "" then
			return "say something"
		end
		say:FireAllClients("loud", string.format("[%s] %s", ctx.plr.Name, text), Rank.hue(ctx.plr))
		return "sent"
	end,
})

add({
	name = "hint",
	alias = { "h" },
	need = "mod",
	use = ";hint <text>",
	run = function(ctx, bits)
		local text = Fmt.esc(Fmt.cut(Args.rest(bits, 1), Cfg.adm.cap))
		if text == "" then
			return "say something"
		end
		say:FireAllClients("hint", text, Rank.hue(ctx.plr))
		return "sent"
	end,
})

add({
	name = "time",
	need = "mod",
	use = ";time <0-24>",
	run = function(ctx, bits)
		local n = Args.num(bits[1], 0, 24, 14)
		Lighting.ClockTime = n
		return "clock set to " .. tostring(n)
	end,
})

add({
	name = "clean",
	need = "mod",
	use = ";clean",
	run = function()
		local box = workspace:FindFirstChild(Cfg.adm.binName)
		if not box then
			return "no " .. Cfg.adm.binName .. " folder in workspace"
		end
		local n = 0
		for _, thing in box:GetChildren() do
			thing:Destroy()
			n += 1
		end
		return string.format("wiped %d things", n)
	end,
})

add({
	name = "cash",
	need = "admin",
	use = ";cash <who> <n>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local n = Args.num(bits[2], -1e9, 1e9, 0)
		for _, plr in pile do
			local got = Store.bump(plr, "cash", n)
			if got then
				plr:SetAttribute("Cash", got)
			end
		end
		return string.format("moved %s cash on %s", Fmt.num(n), Args.names(pile))
	end,
})

add({
	name = "grant",
	need = "admin",
	use = ";grant <who> <item>",
	run = function(ctx, bits)
		local Buy = require(SSS:WaitForChild("Shop"):WaitForChild("Buy"))
		local pile = Args.plrs(ctx, bits[1])
		local key = string.lower(bits[2] or "")
		for _, plr in pile do
			local _, line = Buy.free(plr, key)
			ctx.out(line)
		end
		return nil
	end,
})

add({
	name = "owns",
	need = "mod",
	use = ";owns <who>",
	run = function(ctx, bits)
		local plr = Args.plr(ctx, bits[1])
		if not plr then
			return "nobody like " .. tostring(bits[1])
		end
		local d = Store.get(plr)
		if not d or type(d.owns) ~= "table" then
			return plr.Name .. " has nothing saved yet"
		end
		local pile = {}
		for key, n in d.owns do
			table.insert(pile, string.format("%s x%d", key, n))
		end
		if #pile == 0 then
			return plr.Name .. " owns nothing"
		end
		return plr.Name .. ": " .. table.concat(pile, ", ")
	end,
})

add({
	name = "rank",
	need = "owner",
	use = ";rank <who> <tier>",
	run = function(ctx, bits)
		local tier = string.lower(bits[2] or "")
		if not Rank.tiers[tier] then
			return "tiers: player, vip, mod, admin, owner"
		end
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			plr:SetAttribute(Rank.key, tier)
		end
		return string.format("%s is now %s for this round", Args.names(pile), tier)
	end,
})

add({
	name = "bypass",
	need = "owner",
	use = ";bypass <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		local out = {}
		for _, plr in pile do
			local on = not plr:GetAttribute("AcOff")
			plr:SetAttribute("AcOff", if on then true else nil)
			table.insert(out, string.format("%s %s", plr.Name, if on then "off" else "on"))
		end
		return "anti cheat: " .. table.concat(out, ", ")
	end,
})

add({
	name = "flags",
	need = "mod",
	use = ";flags <who>",
	run = function(ctx, bits)
		local Pen = require(SSS:WaitForChild("Ac"):WaitForChild("Pen"))
		local pile = Args.plrs(ctx, bits[1])
		for _, plr in pile do
			ctx.out(string.format("%s has %d flags", plr.Name, Pen.count(plr)))
		end
		return nil
	end,
})

add({
	name = "ping",
	need = "mod",
	use = ";ping <who>",
	run = function(ctx, bits)
		local pile = Args.plrs(ctx, bits[1])
		if #pile == 0 then
			pile = { ctx.plr }
		end
		for _, plr in pile do
			ctx.out(string.format("%s: %dms", plr.Name, plr:GetNetworkPing() * 1000 // 1))
		end
		return nil
	end,
})

add({
	name = "here",
	need = "mod",
	use = ";here",
	run = function(ctx)
		local pile = {}
		for _, plr in Players:GetPlayers() do
			table.insert(pile, string.format("%s [%s]", plr.Name, Rank.of(plr)))
		end
		return string.format("%d/%d: %s", #pile, Players.MaxPlayers, table.concat(pile, ", "))
	end,
})

add({
	name = "up",
	need = "mod",
	use = ";up",
	run = function()
		return string.format("up for %s, started %s", Fmt.dur(os.time() - born), Fmt.clock(born))
	end,
})

add({
	name = "ver",
	need = "mod",
	use = ";ver",
	run = function()
		return string.format("place %d, build %d, job %s", game.PlaceId, game.PlaceVersion, if game.JobId ~= "" then game.JobId else "studio")
	end,
})

add({
	name = "find",
	need = "mod",
	use = ";find <who>",
	run = function(ctx, bits)
		local plr = Args.plr(ctx, bits[1])
		if not plr then
			return "nobody like " .. tostring(bits[1])
		end
		local d = Store.get(plr)
		local r = root(plr)
		ctx.out(string.format("%s, id %d, %dd old, rank %s", Fmt.who(plr), plr.UserId, plr.AccountAge, Rank.of(plr)))
		if d then
			ctx.out(string.format("visits %d, played %s, cash %s", d.visits, Fmt.dur(d.secs), Fmt.num(d.cash)))
		end
		if r then
			ctx.out(string.format("at %d %d %d", r.Position.X, r.Position.Y, r.Position.Z))
		end
		return nil
	end,
})

add({
	name = "boot",
	alias = { "shutdown" },
	need = "owner",
	use = ";boot",
	run = function(ctx)
		local Go = require(SSS:WaitForChild("Soft"):WaitForChild("Go"))
		task.spawn(Go.run, ctx.plr.Name)
		return "moving everyone to a fresh server"
	end,
})

return Cmds
