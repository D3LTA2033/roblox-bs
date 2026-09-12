-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local Net = require(Bits:WaitForChild("Net"))
local Mk = require(Bits:WaitForChild("Mk"))
local Rank = require(Bits:WaitForChild("Rank"))

local me = Players.LocalPlayer
local wire = Net.ev("adm")
local ask = Net.fn("list")
local ink = Mk.ink

local open = false
local mark: Player? = nil
local uses: { string } = {}
local past: { string } = {}
local seat = 0
local spot = 0
local rows: { [Player]: Instance } = {}

local gui = Mk.new("ScreenGui", {
	Name = "Bs",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 40,
	Parent = me:WaitForChild("PlayerGui"),
})

local shell = Mk.new("Frame", {
	Name = "Shell",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.fromOffset(560, 350),
	BackgroundColor3 = ink.sheet,
	BorderSizePixel = 0,
	Visible = false,
	Parent = gui,
}, { Mk.round(10), Mk.edge() })

local fit = Mk.new("UIScale", { Parent = shell })

local bar = Mk.new("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
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

Mk.text("bs panel", {
	Position = UDim2.fromOffset(12, 0),
	Size = UDim2.new(1, -80, 1, 0),
	TextSize = 15,
	Font = Enum.Font.GothamBold,
	Parent = bar,
})

local chip = Mk.text("", {
	Position = UDim2.new(1, -120, 0, 0),
	Size = UDim2.fromOffset(80, 34),
	TextSize = 12,
	TextColor3 = ink.dim,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = bar,
})

local shut = Mk.btn("x", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(22, 22),
	BackgroundColor3 = ink.step,
	TextSize = 14,
	Parent = bar,
})

local body = Mk.new("Frame", {
	Position = UDim2.fromOffset(0, 34),
	Size = UDim2.new(1, 0, 1, -34),
	BackgroundTransparency = 1,
	Parent = shell,
}, { Mk.pad(10) })

local list = Mk.new("ScrollingFrame", {
	Size = UDim2.new(0, 170, 1, 0),
	BackgroundColor3 = ink.back,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = ink.edge,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = body,
}, { Mk.round(8), Mk.stack(4), Mk.pad(6) })

local right = Mk.new("Frame", {
	Position = UDim2.new(0, 180, 0, 0),
	Size = UDim2.new(1, -180, 1, 0),
	BackgroundTransparency = 1,
	Parent = body,
})

local log = Mk.new("ScrollingFrame", {
	Size = UDim2.new(1, 0, 1, -140),
	BackgroundColor3 = ink.back,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = ink.edge,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = right,
}, { Mk.round(8), Mk.stack(2), Mk.pad(6) })

local grid = Mk.new("Frame", {
	Position = UDim2.new(0, 0, 1, -134),
	Size = UDim2.new(1, 0, 0, 96),
	BackgroundTransparency = 1,
	Parent = right,
}, {
	Mk.new("UIGridLayout", {
		CellSize = UDim2.new(0.25, -6, 0, 26),
		CellPadding = UDim2.fromOffset(6, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
})

local box = Mk.new("TextBox", {
	Position = UDim2.new(0, 0, 1, -30),
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = ink.back,
	BorderSizePixel = 0,
	Text = "",
	PlaceholderText = Cfg.prefix .. "kick name reason",
	PlaceholderColor3 = ink.dim,
	TextColor3 = ink.text,
	TextSize = 14,
	Font = Enum.Font.Code,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	Parent = right,
}, { Mk.round(8), Mk.pad(8) })

local tip = Mk.text("", {
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -10, 1, -28),
	Size = UDim2.fromOffset(220, 26),
	TextColor3 = ink.dim,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Right,
	Parent = right,
})

local function write(line: string)
	spot += 1
	Mk.text(Fmt.esc(line), {
		Size = UDim2.new(1, -4, 0, 16),
		TextSize = 12,
		Font = Enum.Font.Code,
		TextColor3 = if string.find(line, "[ac]", 1, true) then ink.hot else ink.text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		LayoutOrder = spot,
		Parent = log,
	})
	local kids = log:GetChildren()
	local count = 0
	for _, kid in kids do
		if kid:IsA("TextLabel") then
			count += 1
		end
	end
	if count > Cfg.adm.lines then
		for _, kid in kids do
			if kid:IsA("TextLabel") then
				kid:Destroy()
				break
			end
		end
	end
	task.defer(function()
		log.CanvasPosition = Vector2.new(0, math.max(0, log.AbsoluteCanvasSize.Y))
	end)
end

local function send(text: string)
	if text == "" then
		return
	end
	table.insert(past, text)
	seat = #past + 1
	write("> " .. text)
	wire:FireServer(text)
end

local function pick(plr: Player?)
	mark = plr
	for other, row in rows do
		local hit = other == plr
		;(row :: any).BackgroundColor3 = if hit then ink.step else ink.sheet
	end
	chip.Text = if plr then "on " .. plr.Name else Rank.of(me)
end

local function sweep()
	for plr, row in rows do
		if plr.Parent == nil then
			row:Destroy()
			rows[plr] = nil
			if mark == plr then
				pick(nil)
			end
		end
	end
end

local function shelf(plr: Player)
	if rows[plr] then
		return
	end
	local row = Mk.btn("", {
		Size = UDim2.new(1, -4, 0, 30),
		BackgroundColor3 = ink.sheet,
		Text = "",
		Parent = list,
	})
	local face = Mk.face(plr.UserId, 22)
	face.Position = UDim2.fromOffset(4, 4)
	face.Parent = row
	Mk.text(plr.Name, {
		Position = UDim2.fromOffset(32, 0),
		Size = UDim2.new(1, -36, 0.6, 0),
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})
	local tag = Mk.text(Rank.of(plr), {
		Position = UDim2.new(0, 32, 0.55, 0),
		Size = UDim2.new(1, -36, 0.45, 0),
		TextSize = 11,
		TextColor3 = Rank.hue(plr),
		Parent = row,
	})
	plr:GetAttributeChangedSignal(Rank.key):Connect(function()
		tag.Text = Rank.of(plr)
		tag.TextColor3 = Rank.hue(plr)
	end)
	row.Activated:Connect(function()
		pick(if mark == plr then nil else plr)
	end)
	rows[plr] = row
end

local quick = {
	{ "kick", "kick %s spam" },
	{ "ban 1d", "ban %s 1d rule break" },
	{ "mute", "mute %s 10m" },
	{ "freeze", "freeze %s" },
	{ "thaw", "thaw %s" },
	{ "bring", "bring %s" },
	{ "to", "to %s" },
	{ "heal", "heal %s" },
	{ "kill", "kill %s" },
	{ "god", "god %s" },
	{ "re", "respawn %s" },
	{ "find", "find %s" },
}

for i, pair in quick do
	local btn = Mk.btn(pair[1], { LayoutOrder = i, Parent = grid })
	btn.Activated:Connect(function()
		local who = if mark then mark.Name else "me"
		send(string.format(pair[2], who))
	end)
end

local function show(on: boolean)
	if not Rank.at(me, Cfg.adm.needAt) then
		on = false
	end
	open = on
	if on then
		shell.Visible = true
		shell.BackgroundTransparency = 1
		TS:Create(shell, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
		if #uses == 0 then
			task.spawn(function()
				local ok, got = pcall(ask.InvokeServer, ask)
				if ok and type(got) == "table" then
					uses = got
				end
			end)
		end
	else
		shell.Visible = false
	end
end

shut.Activated:Connect(function()
	show(false)
end)

box.FocusLost:Connect(function(fired)
	local text = box.Text
	box.Text = ""
	tip.Text = ""
	if fired then
		send(text)
		box:CaptureFocus()
	end
end)

box:GetPropertyChangedSignal("Text"):Connect(function()
	local want = string.lower(string.gsub(box.Text, "^" .. Cfg.prefix, ""))
	tip.Text = ""
	if want == "" then
		return
	end
	for _, use in uses do
		local name = string.match(use, "^" .. Cfg.prefix .. "(%S+)")
		if name and string.sub(name, 1, #want) == want then
			tip.Text = use
			break
		end
	end
end)

UIS.InputBegan:Connect(function(input, typing)
	if typing then
		if input.KeyCode == Enum.KeyCode.Up and box:IsFocused() and #past > 0 then
			seat = math.max(1, seat - 1)
			box.Text = past[seat]
		elseif input.KeyCode == Enum.KeyCode.Down and box:IsFocused() then
			seat = math.min(#past + 1, seat + 1)
			box.Text = past[seat] or ""
		end
		return
	end
	if input.KeyCode == Cfg.adm.key then
		show(not open)
	end
end)

do
	local grab: Vector2? = nil
	local from = shell.Position
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			grab = Vector2.new(input.Position.X, input.Position.Y)
			from = shell.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if not grab then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local step = Vector2.new(input.Position.X, input.Position.Y) - grab
		shell.Position = UDim2.new(from.X.Scale, from.X.Offset + step.X, from.Y.Scale, from.Y.Offset + step.Y)
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			grab = nil
		end
	end)
end

if UIS.TouchEnabled then
	local nub = Mk.btn("bs", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.fromOffset(46, 46),
		BackgroundColor3 = ink.back,
		Parent = gui,
	})
	nub.Activated:Connect(function()
		show(not open)
	end)
	me:GetAttributeChangedSignal(Rank.key):Connect(function()
		nub.Visible = Rank.at(me, Cfg.adm.needAt)
	end)
	nub.Visible = Rank.at(me, Cfg.adm.needAt)
end

local function size()
	local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	fit.Scale = math.clamp(view.X / 900, 0.62, 1.1)
end

if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(size)
end
size()

wire.OnClientEvent:Connect(function(kind, text)
	if kind == "out" then
		write(text)
	end
end)

Players.PlayerAdded:Connect(shelf)
Players.PlayerRemoving:Connect(sweep)
for _, plr in Players:GetPlayers() do
	shelf(plr)
end

me:GetAttributeChangedSignal(Rank.key):Connect(function()
	chip.Text = Rank.of(me)
	if not Rank.at(me, Cfg.adm.needAt) then
		show(false)
	end
end)

chip.Text = Rank.of(me)
