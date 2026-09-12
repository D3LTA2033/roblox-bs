-- made by @mcs.s on discord

local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local TCS = game:GetService("TextChatService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Net = require(Bits:WaitForChild("Net"))
local Rank = require(Bits:WaitForChild("Rank"))
local Bans = require(script.Parent.Bans)
local Cmds = require(script.Parent.Cmds)
local Mute = require(script.Parent.Mute)
local Grd = require(SSS:WaitForChild("Gate"):WaitForChild("Grd"))
local Hook = require(SSS:WaitForChild("Hooks"):WaitForChild("Hook"))

local wire = Net.ev("adm")
local ask = Net.fn("list")

local function reply(plr: Player, line: string)
	if plr.Parent then
		wire:FireClient(plr, "out", Fmt.cut(line, 300))
	end
end

local function log(plr: Player, text: string, res: string?)
	if not Cfg.adm.log then
		return
	end
	Hook.send("adm", Hook.card("command", Hook.hue.info)
		:who(plr)
		:row("rank", Rank.of(plr))
		:row("ran", Cfg.prefix .. text, true)
		:row("back", res or "-", true))
end

local function run(plr: Player, text: string)
	text = string.gsub(text, "^%s+", "")
	if text == "" then
		return
	end
	local bits = {}
	for piece in string.gmatch(text, "%S+") do
		table.insert(bits, piece)
	end
	local name = string.lower(table.remove(bits, 1) or "")
	local def = Cmds.by[name]
	if not def then
		reply(plr, string.format("no command called %q, try %scmds", name, Cfg.prefix))
		return
	end
	local lvl = Rank.lvl(plr)
	if lvl < Rank.need(def.need) then
		reply(plr, "that one needs " .. def.need)
		return
	end
	local ctx = {
		plr = plr,
		lvl = lvl,
		out = function(line: any)
			reply(plr, tostring(line))
		end,
	}
	local ok, res = pcall(def.run, ctx, bits)
	if not ok then
		reply(plr, "that broke: " .. Fmt.cut(tostring(res), 120))
		warn(string.format("[adm] %s ran %s and it broke: %s", plr.Name, name, tostring(res)))
		log(plr, text, "error")
		return
	end
	if type(res) == "string" then
		reply(plr, res)
	end
	log(plr, text, if type(res) == "string" then res else nil)
end

Grd.hook(wire, "adm", 12, 10, function(plr, text)
	local clean = Grd.str(text, 300)
	if not clean or not Rank.at(plr, Cfg.adm.needAt) then
		return
	end
	if string.sub(clean, 1, #Cfg.prefix) == Cfg.prefix then
		clean = string.sub(clean, #Cfg.prefix + 1)
	end
	run(plr, clean)
end)

local function chat(plr: Player, text: string): boolean
	if Mute.on(plr.UserId) then
		local left = Mute.left(plr.UserId)
		reply(plr, if left < 0 then "you are muted" else "you are muted for " .. Fmt.dur(left))
		return false
	end
	if string.sub(text, 1, #Cfg.prefix) == Cfg.prefix and Rank.at(plr, Cfg.adm.needAt) then
		task.spawn(run, plr, string.sub(text, #Cfg.prefix + 1))
		return false
	end
	return true
end

if TCS.ChatVersion == Enum.ChatVersion.TextChatService then
	local function wrap(chan: Instance)
		if not chan:IsA("TextChannel") then
			return
		end
		chan.ShouldDeliverCallback = function(msg, src)
			local plr = Players:GetPlayerByUserId(src.UserId)
			if not plr then
				return true
			end
			return chat(plr, msg.Text)
		end
	end
	local chans = TCS:WaitForChild("TextChannels")
	chans.ChildAdded:Connect(wrap)
	for _, chan in chans:GetChildren() do
		wrap(chan)
	end
else
	Players.PlayerAdded:Connect(function(plr)
		plr.Chatted:Connect(function(text)
			chat(plr, text)
		end)
	end)
end

ask.OnServerInvoke = function(plr)
	local out = {}
	if not Rank.at(plr, Cfg.adm.needAt) then
		return out
	end
	local lvl = Rank.lvl(plr)
	for _, def in Cmds.list do
		if lvl >= Rank.need(def.need) then
			table.insert(out, def.use)
		end
	end
	table.sort(out)
	return out
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(Bans.check, plr)
end)

for _, plr in Players:GetPlayers() do
	task.spawn(Bans.check, plr)
end

task.spawn(function()
	while task.wait(30) do
		for _, plr in Players:GetPlayers() do
			if plr:GetAttribute("Froze") then
				local char = plr.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") and not root.Anchored then
					root.Anchored = true
				end
			end
		end
	end
end)
