-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))
local Card = require(script.Parent.Card)

if not Cfg.greet.on then
	return
end

local me = Players.LocalPlayer
local pipe = Net.ev("greet")

local gui = Instance.new("ScreenGui")
gui.Name = "Greet"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = me:WaitForChild("PlayerGui")

local host = Card.host(gui)
local live: { Frame } = {}
local line: { any } = {}
local busy = false

local function put(info: any)
	local box = Card.make(host, info)
	table.insert(live, box)
	if #live > Cfg.greet.slots then
		local old = table.remove(live, 1)
		if old then
			Card.drop(old)
		end
	end
	task.delay(Cfg.greet.hold, function()
		local at = table.find(live, box)
		if at then
			table.remove(live, at)
			Card.drop(box)
		end
	end)
end

local function pump()
	if busy then
		return
	end
	busy = true
	while #line > 0 do
		put(table.remove(line, 1))
		task.wait(0.25)
	end
	busy = false
end

pipe.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" or type(info.id) ~= "number" then
		return
	end
	if #line > 12 then
		return
	end
	if info.id ~= me.UserId then
		local ok, pal = pcall(function()
			return me:IsFriendsWith(info.id)
		end)
		info.pal = ok and pal == true
	end
	table.insert(line, info)
	task.spawn(pump)
end)
