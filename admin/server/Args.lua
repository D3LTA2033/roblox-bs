-- made by @mcs.s on discord

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Fmt = require(Bits:WaitForChild("Fmt"))
local Rank = require(Bits:WaitForChild("Rank"))

local Args = {}

local function add(pile: { Player }, plr: Player?)
	if plr and not table.find(pile, plr) then
		table.insert(pile, plr)
	end
end

local function one(word: string): Player?
	local low = string.lower(word)
	local hit: Player? = nil
	for _, plr in Players:GetPlayers() do
		if string.lower(plr.Name) == low or string.lower(plr.DisplayName) == low then
			return plr
		end
	end
	for _, plr in Players:GetPlayers() do
		if string.sub(string.lower(plr.Name), 1, #low) == low then
			if hit then
				return nil
			end
			hit = plr
		end
	end
	if hit then
		return hit
	end
	for _, plr in Players:GetPlayers() do
		if string.find(string.lower(plr.DisplayName), low, 1, true) then
			return plr
		end
	end
	return nil
end

function Args.plrs(ctx, word: string?): { Player }
	local pile: { Player } = {}
	if not word or word == "" then
		return pile
	end
	for part in string.gmatch(string.lower(word), "[^,]+") do
		if part == "me" then
			add(pile, ctx.plr)
		elseif part == "all" or part == "*" then
			for _, plr in Players:GetPlayers() do
				add(pile, plr)
			end
		elseif part == "others" then
			for _, plr in Players:GetPlayers() do
				if plr ~= ctx.plr then
					add(pile, plr)
				end
			end
		elseif part == "rng" or part == "random" then
			local live = Players:GetPlayers()
			add(pile, live[math.random(#live)])
		elseif part == "nil" or part == "low" then
			for _, plr in Players:GetPlayers() do
				if Rank.lvl(plr) == 0 then
					add(pile, plr)
				end
			end
		elseif string.sub(part, 1, 5) == "team:" then
			local team = Teams:FindFirstChild(string.sub(part, 6))
			if team and team:IsA("Team") then
				for _, plr in team:GetPlayers() do
					add(pile, plr)
				end
			end
		elseif string.sub(part, 1, 1) == "@" then
			add(pile, one(string.sub(part, 2)))
		else
			add(pile, one(part))
		end
	end
	return pile
end

function Args.plr(ctx, word: string?): Player?
	return Args.plrs(ctx, word)[1]
end

function Args.id(word: string?): (number?, string?)
	if not word or word == "" then
		return nil, nil
	end
	local here = Players:FindFirstChild(word)
	if here and here:IsA("Player") then
		return here.UserId, here.Name
	end
	local asNum = tonumber(word)
	if asNum and asNum > 0 then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, asNum)
		return math.floor(asNum), if ok then name else tostring(asNum)
	end
	local ok, id = pcall(Players.GetUserIdFromNameAsync, Players, word)
	if ok and type(id) == "number" then
		return id, word
	end
	return nil, nil
end

function Args.num(word: string?, low: number, high: number, fall: number): number
	local got = tonumber(word)
	if not got or got ~= got then
		return fall
	end
	return math.clamp(got, low, high)
end

function Args.secs(word: string?): number
	if not word then
		return -1
	end
	return Fmt.span(word) or -1
end

function Args.rest(bits: { string }, from: number, fall: string?): string
	if #bits < from then
		return fall or ""
	end
	return table.concat(bits, " ", from, #bits)
end

function Args.names(pile: { Player }): string
	local out = {}
	for _, plr in pile do
		table.insert(out, plr.Name)
	end
	if #out == 0 then
		return "nobody"
	end
	return table.concat(out, ", ")
end

return Args
