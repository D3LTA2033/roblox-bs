-- made by @mcs.s on discord

local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")
local TPS = game:GetService("TeleportService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))

local Go = {}

local say = Net.ev("say")
local busy = false
local code: string? = nil

function Go.mark(): string?
	if code then
		return code
	end
	local ok, got = pcall(TPS.ReserveServer, TPS, game.PlaceId)
	if ok and type(got) == "string" then
		code = got
	end
	return code
end

function Go.move(pile: { Player }): number
	local spot = Go.mark()
	if not spot then
		return 0
	end
	local sent = 0
	local trip = Instance.new("TeleportOptions")
	trip.ReservedServerAccessCode = spot
	trip:SetTeleportData({ bounce = true, at = os.time() })
	for _, plr in pile do
		local ok = pcall(TPS.TeleportAsync, TPS, game.PlaceId, { plr }, trip)
		if ok then
			sent += 1
		end
		task.wait(0.1)
	end
	return sent
end

function Go.run(by: string?)
	if busy or not Cfg.soft.on then
		return
	end
	busy = true
	say:FireAllClients("loud", Cfg.soft.word, Color3.fromRGB(255, 190, 80))
	local ok, Hook = pcall(function()
		return require(SSS:WaitForChild("Hooks"):WaitForChild("Hook"))
	end)
	if ok then
		Hook.send("main", Hook.card("soft shutdown", Hook.hue.warn):row("by", by or "server"):row("here", #Players:GetPlayers()))
	end
	task.wait(Cfg.soft.hold)
	Go.move(Players:GetPlayers())
	task.delay(10, function()
		busy = false
	end)
end

function Go.hold()
	if Run:IsStudio() then
		return
	end
	local pile = Players:GetPlayers()
	if #pile == 0 then
		return
	end
	say:FireAllClients("loud", Cfg.soft.word, Color3.fromRGB(255, 190, 80))
	Go.move(pile)
	local cut = os.clock() + 25
	while #Players:GetPlayers() > 0 and os.clock() < cut do
		task.wait(0.5)
	end
end

return Go
