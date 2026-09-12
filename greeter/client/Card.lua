-- made by @mcs.s on discord

local RepS = game:GetService("ReplicatedStorage")
local SSv = game:GetService("SoundService")
local TS = game:GetService("TweenService")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Rank = require(Bits:WaitForChild("Rank"))

local Card = {}

local ink = {
	sheet = Color3.fromRGB(26, 28, 34),
	text = Color3.fromRGB(234, 237, 243),
	dim = Color3.fromRGB(154, 160, 174),
}

local fade = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

function Card.host(into: Instance): Frame
	local host = Instance.new("Frame")
	host.Name = "Cards"
	host.AnchorPoint = Vector2.new(0.5, 0)
	host.Position = UDim2.new(0.5, 0, 0, 16)
	host.Size = UDim2.fromOffset(320, 240)
	host.BackgroundTransparency = 1
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 8)
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = host
	host.Parent = into
	return host
end

function Card.make(host: Frame, info: any): Frame
	local tier = Rank.tiers[info.rank] or Rank.tiers.player
	local hue = tier.hue

	local box = Instance.new("Frame")
	box.Size = UDim2.fromOffset(300, 56)
	box.BackgroundColor3 = ink.sheet
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0

	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0, 10)
	round.Parent = box

	local edge = Instance.new("UIStroke")
	edge.Color = hue
	edge.Thickness = 1
	edge.Transparency = 1
	edge.Parent = box

	local bulb = Instance.new("Frame")
	bulb.Size = UDim2.fromOffset(4, 40)
	bulb.Position = UDim2.fromOffset(8, 8)
	bulb.BackgroundColor3 = hue
	bulb.BackgroundTransparency = 1
	bulb.BorderSizePixel = 0
	local bround = Instance.new("UICorner")
	bround.CornerRadius = UDim.new(1, 0)
	bround.Parent = bulb
	bulb.Parent = box

	local face = Instance.new("ImageLabel")
	face.Size = UDim2.fromOffset(40, 40)
	face.Position = UDim2.fromOffset(20, 8)
	face.BackgroundTransparency = 1
	face.ImageTransparency = 1
	face.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=60&h=60", info.id)
	local fround = Instance.new("UICorner")
	fround.CornerRadius = UDim.new(0.5, 0)
	fround.Parent = face
	face.Parent = box

	local top = Instance.new("TextLabel")
	top.Position = UDim2.fromOffset(68, 10)
	top.Size = UDim2.new(1, -78, 0, 18)
	top.BackgroundTransparency = 1
	top.Font = Enum.Font.GothamBold
	top.TextSize = 14
	top.TextColor3 = ink.text
	top.TextTransparency = 1
	top.TextXAlignment = Enum.TextXAlignment.Left
	top.RichText = true
	local chip = if info.pal then " <font color=\"#6ee7a8\">friend</font>" else ""
	top.Text = string.format("%s <font color=\"#%s\">%s</font>%s", Fmt.esc(info.name), hue:ToHex(), tier.word, chip)
	top.Parent = box

	local low = Instance.new("TextLabel")
	low.Position = UDim2.fromOffset(68, 28)
	low.Size = UDim2.new(1, -78, 0, 18)
	low.BackgroundTransparency = 1
	low.Font = Enum.Font.Gotham
	low.TextSize = 12
	low.TextColor3 = ink.dim
	low.TextTransparency = 1
	low.TextXAlignment = Enum.TextXAlignment.Left
	low.Text = if info.new
		then Cfg.greet.first
		else string.format("%s, visit %d, %s played", Cfg.greet.back, info.visits, Fmt.dur(info.secs))
	low.Parent = box

	box.Parent = host

	TS:Create(box, fade, { BackgroundTransparency = 0.05 }):Play()
	TS:Create(edge, fade, { Transparency = 0.4 }):Play()
	TS:Create(bulb, fade, { BackgroundTransparency = 0 }):Play()
	TS:Create(face, fade, { ImageTransparency = 0 }):Play()
	TS:Create(top, fade, { TextTransparency = 0 }):Play()
	TS:Create(low, fade, { TextTransparency = 0 }):Play()

	if Cfg.greet.sound ~= "" and tier.loud then
		local ding = Instance.new("Sound")
		ding.SoundId = Cfg.greet.sound
		ding.Volume = 0.4
		SSv:PlayLocalSound(ding)
		task.delay(4, function()
			ding:Destroy()
		end)
	end

	return box
end

function Card.drop(box: Frame)
	local out = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	for _, thing in box:GetDescendants() do
		if thing:IsA("TextLabel") then
			TS:Create(thing, out, { TextTransparency = 1 }):Play()
		elseif thing:IsA("ImageLabel") then
			TS:Create(thing, out, { ImageTransparency = 1 }):Play()
		elseif thing:IsA("UIStroke") then
			TS:Create(thing, out, { Transparency = 1 }):Play()
		elseif thing:IsA("Frame") then
			TS:Create(thing, out, { BackgroundTransparency = 1 }):Play()
		end
	end
	local slide = TS:Create(box, out, { BackgroundTransparency = 1, Size = UDim2.fromOffset(300, 0) })
	slide:Play()
	slide.Completed:Once(function()
		box:Destroy()
	end)
end

return Card
