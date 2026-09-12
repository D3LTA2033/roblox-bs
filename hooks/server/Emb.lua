-- made by @mcs.s on discord

local RepS = game:GetService("ReplicatedStorage")

local Fmt = require(RepS:WaitForChild("Bits"):WaitForChild("Fmt"))

local Emb = {}
Emb.__index = Emb

Emb.hue = {
	good = 0x57F287,
	bad = 0xED4245,
	warn = 0xFEE75C,
	info = 0x5865F2,
	dim = 0x4F545C,
}

function Emb.new(title: string, hue: number?)
	return setmetatable({
		raw = {
			title = Fmt.cut(title, 240),
			color = hue or Emb.hue.info,
			fields = {},
			timestamp = DateTime.now():ToIsoDate(),
			footer = { text = string.format("job %s", if game.JobId ~= "" then string.sub(game.JobId, 1, 8) else "studio") },
		},
	}, Emb)
end

function Emb:txt(body: string)
	self.raw.description = Fmt.cut(body, 3800)
	return self
end

function Emb:row(name: string, val: any, wide: boolean?)
	if #self.raw.fields >= 24 then
		return self
	end
	table.insert(self.raw.fields, {
		name = Fmt.cut(name, 250),
		value = Fmt.cut(if val == nil or val == "" then "-" else tostring(val), 1000),
		inline = wide ~= true,
	})
	return self
end

function Emb:who(plr: Player)
	self.raw.author = { name = Fmt.cut(Fmt.who(plr), 250) }
	return self:row("id", plr.UserId)
end

function Emb:at(spot: Vector3)
	return self:row("spot", string.format("%d, %d, %d", spot.X, spot.Y, spot.Z))
end

function Emb:out(): any
	return self.raw
end

return Emb
