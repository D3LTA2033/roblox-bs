-- made by @mcs.s on discord

local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Mk = require(Bits:WaitForChild("Mk"))
local Net = require(Bits:WaitForChild("Net"))

if not Cfg.shop.on then
	return
end

local me = Players.LocalPlayer
local pipe = Net.ev("shop")
local menu = Net.fn("menu")
local ink = Mk.ink

local open = false
local tab = "cash"
local book: any = nil
local busy = false

local gui = Mk.new("ScreenGui", {
	Name = "Shop",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 35,
	Parent = me:WaitForChild("PlayerGui"),
})

local shell = Mk.new("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(480, 340),
	BackgroundColor3 = ink.sheet,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
}, { Mk.round(10), Mk.edge() })

local fit = Mk.new("UIScale", { Parent = shell })

local bar = Mk.new("Frame", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = ink.back,
	BorderSizePixel = 0,
	Parent = shell,
}, { Mk.round(10) })

Mk.new("Frame", {
	Position = UDim2.new(0, 0, 1, -8),
	Size = UDim2.new(1, 0, 0, 8),
	BackgroundColor3 = ink.back,
	BorderSizePixel = 0,
	Parent = bar,
})

Mk.text(Cfg.shop.name, {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(0, 120, 1, 0),
	TextSize = 16,
	Font = Enum.Font.GothamBold,
	Parent = bar,
})

local purse = Mk.text("0", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -42, 0, 0),
	Size = UDim2.fromOffset(180, 36),
	TextSize = 14,
	TextColor3 = Color3.fromRGB(255, 214, 130),
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = bar,
})

local shut = Mk.btn("x", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(22, 22),
	Parent = bar,
})

local tabs = Mk.new("Frame", {
	Position = UDim2.fromOffset(10, 44),
	Size = UDim2.new(1, -20, 0, 26),
	BackgroundTransparency = 1,
	Parent = shell,
}, { Mk.stack(6, true) })

local rack = Mk.new("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 78),
	Size = UDim2.new(1, -20, 1, -112),
	BackgroundColor3 = ink.back,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = ink.edge,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = shell,
}, { Mk.round(8), Mk.stack(6), Mk.pad(8) })

local note = Mk.text("", {
	Position = UDim2.new(0, 14, 1, -30),
	Size = UDim2.new(1, -28, 0, 24),
	TextSize = 13,
	TextColor3 = ink.dim,
	Parent = shell,
})

local function tell(line: string, good: boolean?)
	note.Text = line
	note.TextColor3 = if good == nil then ink.dim elseif good then Color3.fromRGB(110, 231, 168) else ink.hot
end

local function row(item: any, kind: string)
	local card = Mk.new("Frame", {
		Size = UDim2.new(1, -4, 0, 52),
		BackgroundColor3 = ink.sheet,
		BorderSizePixel = 0,
		Parent = rack,
	}, { Mk.round(8) })

	Mk.text(item.name, {
		Position = UDim2.fromOffset(12, 7),
		Size = UDim2.new(1, -130, 0, 18),
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		Parent = card,
	})

	Mk.text(item.info or "", {
		Position = UDim2.fromOffset(12, 26),
		Size = UDim2.new(1, -130, 0, 16),
		TextSize = 12,
		TextColor3 = ink.dim,
		Parent = card,
	})

	local owned = if kind == "cash" then item.max > 0 and item.own >= item.max else item.own == true
	local label = if kind == "cash" then Fmt.num(item.cost) else "robux"
	if owned then
		Mk.text("owned", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(90, 24),
			TextSize = 13,
			TextColor3 = Color3.fromRGB(110, 231, 168),
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = card,
		})
		return
	end

	local take = Mk.btn(label, {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(96, 26),
		BackgroundColor3 = ink.step,
		Parent = card,
	})

	if kind == "cash" and item.own > 0 and item.max > 1 then
		Mk.text(string.format("x%d", item.own), {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -116, 0, 7),
			Size = UDim2.fromOffset(40, 18),
			TextSize = 12,
			TextColor3 = ink.dim,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = card,
		})
	end

	take.Activated:Connect(function()
		if busy then
			return
		end
		if kind == "cash" then
			busy = true
			tell("buying " .. item.name)
			pipe:FireServer(item.key)
			task.delay(1, function()
				busy = false
			end)
		elseif kind == "pass" then
			local ok = pcall(MPS.PromptGamePassPurchase, MPS, me, item.id)
			if not ok then
				tell("could not open that prompt", false)
			end
		else
			local ok = pcall(MPS.PromptProductPurchase, MPS, me, item.id)
			if not ok then
				tell("could not open that prompt", false)
			end
		end
	end)
end

local function draw()
	for _, kid in rack:GetChildren() do
		if kid:IsA("Frame") then
			kid:Destroy()
		end
	end
	if not book then
		Mk.text("loading", { Size = UDim2.new(1, 0, 0, 20), TextColor3 = ink.dim, Parent = rack })
		return
	end
	purse.Text = Fmt.num(book.purse or 0) .. " cash"
	local pile = book[tab] or {}
	if #pile == 0 then
		Mk.text("nothing here yet", { Size = UDim2.new(1, 0, 0, 20), TextColor3 = ink.dim, Parent = rack })
		return
	end
	for _, item in pile do
		row(item, tab)
	end
end

local chips: { [string]: TextButton } = {}

local function lit()
	for name, chip in chips do
		chip.BackgroundColor3 = if name == tab then ink.step else ink.back
		chip.TextColor3 = if name == tab then ink.text else ink.dim
	end
end

for i, pair in { { "cash", "items" }, { "pass", "passes" }, { "prod", "robux" } } do
	local chip = Mk.btn(pair[2], {
		Size = UDim2.fromOffset(86, 26),
		BackgroundColor3 = ink.back,
		LayoutOrder = i,
		Parent = tabs,
	})
	chips[pair[1]] = chip
	chip.Activated:Connect(function()
		tab = pair[1]
		lit()
		draw()
	end)
end
lit()

local function pull()
	local ok, got = pcall(menu.InvokeServer, menu)
	if ok and type(got) == "table" then
		book = got
		draw()
	else
		tell("shop is not answering, try again", false)
	end
end

local function show(on: boolean)
	open = on
	shell.Visible = on
	if on then
		shell.BackgroundTransparency = 1
		TS:Create(shell, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
		tell("")
		task.spawn(pull)
	end
end

local nub = Mk.btn(Cfg.shop.name, {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -12, 1, -12),
	Size = UDim2.fromOffset(72, 34),
	BackgroundColor3 = ink.back,
	Parent = gui,
})

nub.Activated:Connect(function()
	show(not open)
end)

shut.Activated:Connect(function()
	show(false)
end)

UIS.InputBegan:Connect(function(input, typing)
	if typing then
		return
	end
	if input.KeyCode == Cfg.shop.key then
		show(not open)
	end
end)

pipe.OnClientEvent:Connect(function(kind, ok, line, fresh)
	if kind ~= "back" then
		return
	end
	busy = false
	tell(tostring(line), ok == true)
	if type(fresh) == "table" then
		book = fresh
		draw()
	end
end)

me:GetAttributeChangedSignal("Cash"):Connect(function()
	local cash = me:GetAttribute("Cash")
	if type(cash) == "number" then
		if book then
			book.purse = cash
		end
		purse.Text = Fmt.num(cash) .. " cash"
	end
end)

local function size()
	local cam = workspace.CurrentCamera
	local view = if cam then cam.ViewportSize else Vector2.new(1280, 720)
	fit.Scale = math.clamp(view.X / 900, 0.68, 1.1)
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(size)
end
size()
