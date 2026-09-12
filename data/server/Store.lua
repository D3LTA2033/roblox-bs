-- made by @mcs.s on discord

local DSS = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")

local Cfg = require(RepS:WaitForChild("Bits"):WaitForChild("Cfg"))

local Store = {}

local db = DSS:GetDataStore(Cfg.data.name, Cfg.data.scope)
local held: { [Player]: { d: any, born: number, busy: boolean } } = {}
local me = if game.JobId ~= "" then game.JobId else "studio"

local function copy(src: any): any
	local out = {}
	for k, v in src do
		out[k] = if type(v) == "table" then copy(v) else v
	end
	return out
end

local function fill(got: any): any
	local out = if type(got) == "table" then got else {}
	for k, v in Cfg.data.base do
		if out[k] == nil then
			out[k] = if type(v) == "table" then copy(v) else v
		end
	end
	return out
end

local function slot(id: number): string
	return "p" .. id
end

local function budget(kind: Enum.DataStoreRequestType): boolean
	local spins = 0
	while DSS:GetRequestBudgetForRequestType(kind) < 1 do
		task.wait(0.7)
		spins += 1
		if spins > 50 then
			return false
		end
	end
	return true
end

local function push(fn: () -> any, tries: number?): (boolean, any)
	local max = tries or 4
	local nap = 1
	for i = 1, max do
		local ok, res = pcall(fn)
		if ok then
			return true, res
		end
		if i == max then
			warn("[store] gave up: " .. tostring(res))
			return false, res
		end
		task.wait(nap)
		nap = math.min(nap * 2, 12)
	end
	return false, nil
end

function Store.load(plr: Player): any?
	if held[plr] then
		return held[plr].d
	end
	for pass = 1, Cfg.data.tries do
		if plr.Parent == nil then
			return nil
		end
		if not budget(Enum.DataStoreRequestType.UpdateAsync) then
			break
		end
		local taken = false
		local ok, box = push(function()
			return db:UpdateAsync(slot(plr.UserId), function(old)
				local cur = if type(old) == "table" then old else {}
				local lock = cur.lock
				if lock and lock.job ~= me and os.time() - (lock.at or 0) < Cfg.data.stale then
					taken = true
					return nil
				end
				cur.lock = { job = me, at = os.time() }
				cur.d = fill(cur.d)
				return cur
			end)
		end, 3)
		if ok and not taken and type(box) == "table" then
			if plr.Parent == nil then
				Store.drop(plr, box.d)
				return nil
			end
			held[plr] = { d = box.d, born = os.clock(), busy = false }
			return box.d
		end
		if pass < Cfg.data.tries then
			task.wait(Cfg.data.rest)
		end
	end
	return nil
end

function Store.get(plr: Player): any?
	local box = held[plr]
	return box and box.d
end

function Store.wait(plr: Player, max: number?): any?
	local cut = os.clock() + (max or 10)
	while not held[plr] do
		if plr.Parent == nil or os.clock() > cut then
			return nil
		end
		task.wait(0.15)
	end
	return held[plr].d
end

function Store.bump(plr: Player, key: string, by: number): number?
	local d = Store.get(plr)
	if not d or type(d[key]) ~= "number" then
		return nil
	end
	d[key] += by
	return d[key]
end

function Store.save(plr: Player, free: boolean?): boolean
	local box = held[plr]
	if not box or box.busy then
		return false
	end
	box.busy = true
	if not budget(Enum.DataStoreRequestType.UpdateAsync) then
		box.busy = false
		return false
	end
	local ok = push(function()
		return db:UpdateAsync(slot(plr.UserId), function(old)
			local cur = if type(old) == "table" then old else {}
			if cur.lock and cur.lock.job ~= me and not free then
				return nil
			end
			cur.d = box.d
			cur.lock = if free then nil else { job = me, at = os.time() }
			return cur
		end)
	end, if free then 5 else 2)
	box.busy = false
	if free then
		held[plr] = nil
	end
	return ok
end

function Store.drop(plr: Player, data: any?)
	push(function()
		return db:UpdateAsync(slot(plr.UserId), function(old)
			local cur = if type(old) == "table" then old else {}
			if data then
				cur.d = data
			end
			cur.lock = nil
			return cur
		end)
	end, 3)
	held[plr] = nil
end

function Store.all(): { [Player]: any }
	local out = {}
	for plr, box in held do
		out[plr] = box.d
	end
	return out
end

function Store.flush()
	local pile = {}
	for plr in held do
		table.insert(pile, plr)
	end
	local jobs = 0
	for _, plr in pile do
		jobs += 1
		task.spawn(function()
			Store.save(plr, true)
			jobs -= 1
		end)
	end
	local cut = os.clock() + 25
	while jobs > 0 and os.clock() < cut do
		task.wait(0.2)
	end
end

if Run:IsStudio() then
	Players.PlayerRemoving:Connect(function(plr)
		held[plr] = nil
	end)
end

return Store
