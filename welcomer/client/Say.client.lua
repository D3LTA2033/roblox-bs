-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local SG = game:GetService("StarterGui")
local TCS = game:GetService("TextChatService")
local TS = game:GetService("TweenService")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))

local me = Players.LocalPlayer
local pipe = Net.ev("say")

local new = TCS.ChatVersion == Enum.ChatVersion.TextChatService
local chan: TextChannel? = nil

if new then
	task.spawn(function()
		local chans = TCS:WaitForChild("TextChannels", 20)
		if chans then
			chan = chans:WaitForChild("RBXGeneral", 20) :: TextChannel?
		end
	end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "Say"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = me:WaitForChild("PlayerGui")

local band = Instance.new("TextLabel")
band.AnchorPoint = Vector2.new(0.5, 0)
band.Position = UDim2.new(0.5, 0, 0, -40)
band.Size = UDim2.new(0, 420, 0, 34)
band.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
band.BackgroundTransparency = 0.1
band.BorderSizePixel = 0
band.Font = Enum.Font.GothamMedium
band.TextSize = 15
band.TextColor3 = Color3.fromRGB(236, 239, 245)
band.Text = ""
band.RichText = true
band.Visible = false
local round = Instance.new("UICorner")
round.CornerRadius = UDim.new(0, 8)
round.Parent = band
band.Parent = gui

local slot = 0

local function flash(text: string, hue: Color3?)
	slot += 1
	local mine = slot
	band.Text = text
	band.TextColor3 = hue or Color3.fromRGB(236, 239, 245)
	band.Visible = true
	TS:Create(band, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 12),
	}):Play()
	task.delay(4, function()
		if mine ~= slot then
			return
		end
		local back = TS:Create(band, TweenInfo.new(0.25), { Position = UDim2.new(0.5, 0, 0, -40) })
		back:Play()
		back.Completed:Once(function()
			if mine == slot then
				band.Visible = false
			end
		end)
	end)
end

local function line(text: string, hue: Color3?)
	if new then
		if chan then
			chan:DisplaySystemMessage(text)
			return
		end
	end
	local ok = pcall(function()
		SG:SetCore("ChatMakeSystemMessage", {
			Text = string.gsub(text, "<[^>]->", ""),
			Color = hue or Color3.fromRGB(235, 235, 235),
			Font = Enum.Font.SourceSansSemibold,
			TextSize = 18,
		})
	end)
	if not ok then
		print(text)
	end
end

local paint = {
	join = function(text: string, hue: Color3)
		line(string.format("<font color=\"#%s\">%s</font>", hue:ToHex(), text), hue)
	end,
	left = function(text: string, hue: Color3)
		line(string.format("<font color=\"#9aa0ae\">%s</font>", text), hue)
	end,
	motd = function(text: string)
		line(string.format("<font color=\"#7ac7ff\">%s</font>", text))
	end,
	loud = function(text: string, hue: Color3)
		line(string.format("<b><font color=\"#%s\">%s</font></b>", hue:ToHex(), text), hue)
		flash(text, hue)
	end,
	hint = function(text: string, hue: Color3)
		flash(text, hue)
	end,
}

pipe.OnClientEvent:Connect(function(kind, text, hue)
	local fn = paint[kind]
	if fn and type(text) == "string" then
		fn(text, hue or Color3.fromRGB(235, 235, 235))
	end
end)
