-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))

if not Cfg.afk.on then
	return
end

local me = Players.LocalPlayer
local pipe = Net.ev("afk")
local away = false
local said = 0

local function flip(on: boolean)
	if away == on then
		return
	end
	if os.clock() - said < 1.5 then
		return
	end
	away = on
	said = os.clock()
	pipe:FireServer(on)
end

me.Idled:Connect(function()
	flip(true)
end)

local function poke()
	if away then
		flip(false)
	end
end

UIS.InputBegan:Connect(poke)
UIS.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		poke()
	end
end)
