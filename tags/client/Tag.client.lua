-- made by @mcs.s on discord

local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Bin = require(Bits:WaitForChild("Bin"))
local Rank = require(Bits:WaitForChild("Rank"))

if not Cfg.ntag.on then
	return
end

local bins: { [Player]: any } = {}

local function word(plr: Player): string
	local bits = {}
	local tier = Rank.tiers[Rank.of(plr)]
	if tier.loud then
		table.insert(bits, tier.word)
	end
	if plr:GetAttribute("Afk") then
		table.insert(bits, Cfg.afk.word)
	end
	return table.concat(bits, " | ")
end

local function hang(plr: Player, char: Model)
	local bin = bins[plr]
	if not bin then
		return
	end
	bin:wipe()
	local head = char:WaitForChild("Head", 10)
	if not head or char.Parent == nil then
		return
	end

	local board = Instance.new("BillboardGui")
	board.Name = "Nm"
	board.Adornee = head
	board.Size = UDim2.fromOffset(200, 22)
	board.StudsOffsetWorldSpace = Vector3.new(0, Cfg.ntag.lift, 0)
	board.MaxDistance = Cfg.ntag.dist
	board.AlwaysOnTop = false

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamBold
	text.TextScaled = false
	text.TextSize = 14
	text.TextColor3 = Rank.hue(plr)
	text.Text = word(plr)
	text.Parent = board

	local edge = Instance.new("UIStroke")
	edge.Color = Color3.fromRGB(12, 12, 16)
	edge.Thickness = 2
	edge.Transparency = 0.35
	edge.Parent = text

	board.Parent = head
	bin:add(board)

	local function redo()
		text.Text = word(plr)
		text.TextColor3 = Rank.hue(plr)
		board.Enabled = text.Text ~= ""
	end

	bin:add(plr:GetAttributeChangedSignal(Rank.key):Connect(redo))
	bin:add(plr:GetAttributeChangedSignal("Afk"):Connect(redo))
	redo()
end

local function watch(plr: Player)
	bins[plr] = Bin.new()
	plr.CharacterAdded:Connect(function(char)
		hang(plr, char)
	end)
	if plr.Character then
		task.spawn(hang, plr, plr.Character)
	end
end

Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(plr)
	local bin = bins[plr]
	if bin then
		bin:wipe()
	end
	bins[plr] = nil
end)

for _, plr in Players:GetPlayers() do
	watch(plr)
end
