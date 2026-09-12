-- made by @mcs.s on discord

return {
	cash = {
		{ key = "boots", name = "fast boots", cost = 250, max = 1, keep = true, info = "walk speed 24" },
		{ key = "legs", name = "spring legs", cost = 250, max = 1, keep = true, info = "jump 75" },
		{ key = "skin", name = "tough skin", cost = 400, max = 1, keep = true, info = "150 max health" },
		{ key = "kit", name = "med kit", cost = 50, max = 0, keep = false, info = "heal to full" },
	},
	pass = {
		{ key = "vip", name = "vip", id = 0, info = "vip tag, double cash, speed 22" },
		{ key = "glow", name = "glow", id = 0, info = "a light that follows you" },
	},
	prod = {
		{ key = "c1", name = "1,000 cash", id = 0, cash = 1000 },
		{ key = "c5", name = "5,500 cash", id = 0, cash = 5500 },
		{ key = "revive", name = "revive", id = 0, cash = 0 },
	},
}
