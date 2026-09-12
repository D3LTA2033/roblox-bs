-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))

if not Cfg.ac.on or Cfg.ac.beat <= 0 then
	return
end

local me = Players.LocalPlayer
local beat = Net.ev("ac")
local tick = 0

local function ping()
	tick += 1
	beat:FireServer(tick)
end

me.CharacterAdded:Connect(function()
	task.wait(0.5)
	ping()
end)

ping()

while true do
	task.wait(Cfg.ac.beat)
	ping()
end
