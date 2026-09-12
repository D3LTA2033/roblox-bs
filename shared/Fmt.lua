-- made by @mcs.s on discord

local Fmt = {}

local swap = {
	["<"] = "&lt;",
	[">"] = "&gt;",
	["&"] = "&amp;",
	['"'] = "&quot;",
	["'"] = "&apos;",
}

local units = { s = 1, m = 60, h = 3600, d = 86400, w = 604800 }

function Fmt.esc(txt: any): string
	return (tostring(txt):gsub("[<>&\"']", swap))
end

function Fmt.cut(txt: any, max: number): string
	local s = tostring(txt)
	if #s <= max then
		return s
	end
	return string.sub(s, 1, math.max(1, max - 3)) .. "..."
end

function Fmt.num(n: number): string
	local s = string.format("%d", math.floor(n))
	local hits
	repeat
		s, hits = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	until hits == 0
	return s
end

function Fmt.dur(secs: number): string
	local n = math.max(0, math.floor(secs))
	local d = n // 86400
	local h = n % 86400 // 3600
	local m = n % 3600 // 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %dm", h, m)
	elseif m > 0 then
		return string.format("%dm", m)
	end
	return string.format("%ds", n)
end

function Fmt.span(txt: string): number?
	if txt == nil then
		return nil
	end
	local low = string.lower(txt)
	if low == "perm" or low == "forever" or low == "inf" then
		return -1
	end
	local total, found = 0, false
	for n, unit in string.gmatch(low, "(%d+%.?%d*)(%a*)") do
		local mul = units[string.sub(unit, 1, 1)] or 60
		local amt = tonumber(n) or 0
		total += amt * mul
		found = true
	end
	if not found then
		return nil
	end
	return math.floor(total)
end

function Fmt.who(plr: Player): string
	if plr.DisplayName ~= plr.Name then
		return string.format("%s (@%s)", plr.DisplayName, plr.Name)
	end
	return "@" .. plr.Name
end

function Fmt.clock(stamp: number?): string
	return DateTime.fromUnixTimestamp(stamp or os.time()):FormatUniversalTime("HH:mm:ss", "en-us")
end

return Fmt
