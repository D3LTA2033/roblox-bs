-- made by @mcs.s on discord

local Rank = {}

Rank.key = "Rank"

Rank.tiers = {
	player = { lvl = 0, word = "player", hue = Color3.fromRGB(205, 210, 220), loud = false },
	vip = { lvl = 1, word = "vip", hue = Color3.fromRGB(255, 198, 88), loud = true },
	mod = { lvl = 2, word = "mod", hue = Color3.fromRGB(112, 196, 255), loud = true },
	admin = { lvl = 3, word = "admin", hue = Color3.fromRGB(255, 118, 138), loud = true },
	owner = { lvl = 4, word = "owner", hue = Color3.fromRGB(176, 134, 255), loud = true },
}

function Rank.of(plr: Player): string
	local got = plr:GetAttribute(Rank.key)
	if typeof(got) == "string" and Rank.tiers[got] then
		return got
	end
	return "player"
end

function Rank.lvl(plr: Player): number
	return Rank.tiers[Rank.of(plr)].lvl
end

function Rank.need(name: string): number
	local tier = Rank.tiers[name]
	return tier and tier.lvl or 99
end

function Rank.at(plr: Player, name: string): boolean
	return Rank.lvl(plr) >= Rank.need(name)
end

function Rank.hue(plr: Player): Color3
	return Rank.tiers[Rank.of(plr)].hue
end

function Rank.loud(plr: Player): boolean
	return Rank.tiers[Rank.of(plr)].loud
end

function Rank.wait(plr: Player, max: number?): string
	local cut = os.clock() + (max or 5)
	while plr:GetAttribute(Rank.key) == nil do
		if plr.Parent == nil or os.clock() > cut then
			break
		end
		task.wait(0.1)
	end
	return Rank.of(plr)
end

return Rank
