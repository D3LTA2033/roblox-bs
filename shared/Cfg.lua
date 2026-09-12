-- made by @mcs.s on discord

local Cfg = {}

Cfg.tag = "bs"
Cfg.prefix = ";"

Cfg.ac = {
	on = true,
	skipAt = "mod",
	step = 0.3,
	grace = 3,
	pad = 1.45,
	ping = 1.3,
	air = 1.9,
	fall = -6,
	floor = 9,
	clip = 2,
	reach = 24,
	spd = 16,
	jmp = 50,
	hgt = 7.2,
	hp = 100,
	cap = 6,
	decay = 40,
	beat = 3,
	gap = 11,
	ban = false,
	why = "anti cheat: %s",
	bad = {
		"BodyVelocity",
		"BodyThrust",
		"BodyGyro",
		"VectorForce",
		"LinearVelocity",
		"AngularVelocity",
		"AlignPosition",
		"AlignOrientation",
	},
}

Cfg.greet = {
	on = true,
	hold = 5,
	slots = 3,
	sound = "",
	first = "first time here",
	back = "welcome back",
}

Cfg.say = {
	on = true,
	all = true,
	left = true,
	join = "%s joined",
	big = "%s joined, %s",
	out = "%s left",
	motd = {
		"type ;cmds to see what you can run",
		"found a bug? poke @mcs.s on discord",
	},
}

Cfg.ntag = {
	on = true,
	dist = 90,
	lift = 2.6,
}

Cfg.adm = {
	key = Enum.KeyCode.Semicolon,
	needAt = "mod",
	log = true,
	hard = true,
	binName = "Bin",
	toolBox = "Tools",
	cap = 140,
	lines = 60,
}

Cfg.data = {
	name = "plr",
	scope = "v1",
	auto = 180,
	stale = 120,
	tries = 5,
	rest = 4,
	base = {
		visits = 0,
		secs = 0,
		made = 0,
		seen = 0,
		cash = 0,
	},
}

Cfg.afk = {
	on = true,
	boot = 0,
	word = "afk",
}

Cfg.soft = {
	on = true,
	hold = 5,
	word = "server is restarting, hang on",
}

Cfg.gate = {
	burst = 8,
	span = 10,
}

local function seal(t)
	for _, v in t do
		if type(v) == "table" then
			seal(v)
		end
	end
	return table.freeze(t)
end

return seal(Cfg)
