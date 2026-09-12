-- made by @mcs.s on discord

local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))

local Bans = {}

local db = DSS:GetDataStore("bans", Cfg.data.scope)

local function slot(id: number): string
	return "b" .. id
end

local function hard(id: number, why: string, secs: number, by: string): boolean
	if not Cfg.adm.hard then
		return false
	end
	local ok, err = pcall(function()
		Players:BanAsync({
			UserIds = { id },
			Duration = if secs and secs > 0 then secs else -1,
			DisplayReason = Fmt.cut(why, 380),
			PrivateReason = Fmt.cut(why .. " | by " .. by, 380),
			ApplyToUniverse = true,
			ExcludeAltAccounts = false,
		})
	end)
	if not ok then
		warn("[bans] roblox ban failed, falling back: " .. tostring(err))
	end
	return ok
end

function Bans.get(id: number): any?
	local ok, got = pcall(db.GetAsync, db, slot(id))
	if not ok or type(got) ~= "table" then
		return nil
	end
	if got.till and got.till > 0 and os.time() >= got.till then
		task.spawn(function()
			pcall(db.RemoveAsync, db, slot(id))
		end)
		return nil
	end
	return got
end

function Bans.add(id: number, name: string, why: string, secs: number, by: string): boolean
	local rec = {
		name = name,
		why = why,
		by = by,
		at = os.time(),
		till = if secs and secs > 0 then os.time() + secs else -1,
	}
	local soft = hard(id, why, secs, by)
	local ok = pcall(db.SetAsync, db, slot(id), rec)
	if not soft then
		local there = Players:GetPlayerByUserId(id)
		if there then
			there:Kick(Bans.line(rec))
		end
	end
	return ok or soft
end

function Bans.drop(id: number): boolean
	local one = pcall(db.RemoveAsync, db, slot(id))
	local two = true
	if Cfg.adm.hard then
		two = pcall(function()
			Players:UnbanAsync({ UserIds = { id }, ApplyToUniverse = true })
		end)
	end
	return one or two
end

function Bans.line(rec: any): string
	local left = if rec.till and rec.till > 0 then Fmt.dur(rec.till - os.time()) .. " left" else "no end date"
	return string.format("banned: %s (%s)", rec.why or "no reason", left)
end

function Bans.check(plr: Player)
	local rec = Bans.get(plr.UserId)
	if rec and plr.Parent then
		plr:Kick(Bans.line(rec))
	end
end

return Bans
