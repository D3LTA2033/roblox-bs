-- made by @mcs.s on discord

local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Net = require(Bits:WaitForChild("Net"))
local Buy = require(script.Parent.Buy)
local List = require(script.Parent.List)
local Grd = require(SSS:WaitForChild("Gate"):WaitForChild("Grd"))

if not Cfg.shop.on then
	return
end

local pipe = Net.ev("shop")
local menu = Net.fn("menu")

local blank = 0
for _, kind in { "pass", "prod" } do
	for _, it in List[kind] do
		if it.id == 0 then
			blank += 1
		end
	end
end
if blank > 0 then
	warn(string.format("[shop] %d pass or product ids are still 0, fill them in shop/server/List.lua", blank))
end

menu.OnServerInvoke = function(plr)
	return Buy.menu(plr)
end

Grd.hook(pipe, "shop", 8, 10, function(plr, key)
	local want = Grd.str(key, 40)
	if not want then
		return
	end
	local ok, line = Buy.cash(plr, want)
	pipe:FireClient(plr, "back", ok, line, Buy.menu(plr))
end)

MPS.PromptGamePassPurchaseFinished:Connect(function(plr, id, done)
	if not done then
		return
	end
	Buy.mark(plr, id)
	if plr.Parent then
		pipe:FireClient(plr, "back", true, "thanks for buying", Buy.menu(plr))
	end
end)

MPS.ProcessReceipt = function(info)
	local ok, out = pcall(Buy.receipt, info)
	if not ok then
		warn("[shop] receipt broke: " .. tostring(out))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return out
end

local function watch(plr: Player)
	task.spawn(Buy.redo, plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.4)
		if plr.Parent then
			Buy.redo(plr)
		end
	end)
end

Players.PlayerAdded:Connect(watch)

for _, plr in Players:GetPlayers() do
	watch(plr)
end
