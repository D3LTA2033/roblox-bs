-- made by @mcs.s on discord

local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Rank = require(Bits:WaitForChild("Rank"))
local List = require(script.Parent.List)

local order = { "owner", "admin", "mod", "vip" }

local function listed(name: string, id: number): boolean
	local pile = List[name]
	return type(pile) == "table" and table.find(pile, id) ~= nil
end

local function fromGroup(plr: Player): string?
	local g = List.group
	if not g or g.id == 0 then
		return nil
	end
	local ok, got = pcall(plr.GetRankInGroup, plr, g.id)
	if not ok or type(got) ~= "number" or got == 0 then
		return nil
	end
	local best
	for _, name in order do
		local need = g[name]
		if need and got >= need then
			best = name
			break
		end
	end
	return best
end

local function fromPass(plr: Player): string?
	for name, id in List.pass do
		if id ~= 0 then
			local ok, owns = pcall(MPS.UserOwnsGamePassAsync, MPS, plr.UserId, id)
			if ok and owns then
				return name
			end
		end
	end
	return nil
end

local function pick(plr: Player): string
	if List.creator and game.CreatorType == Enum.CreatorType.User and plr.UserId == game.CreatorId then
		return "owner"
	end
	if plr.UserId < 0 then
		return "owner"
	end
	for _, name in order do
		if listed(name, plr.UserId) then
			return name
		end
	end
	return fromGroup(plr) or fromPass(plr) or "player"
end

local function mark(plr: Player)
	local got = pick(plr)
	if plr.Parent then
		plr:SetAttribute(Rank.key, got)
	end
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(mark, plr)
end)

for _, plr in Players:GetPlayers() do
	task.spawn(mark, plr)
end
