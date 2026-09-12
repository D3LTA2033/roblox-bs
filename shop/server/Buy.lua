-- made by @mcs.s on discord

local MPS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local SSS = game:GetService("ServerScriptService")
local RepS = game:GetService("ReplicatedStorage")

local Bits = RepS:WaitForChild("Bits")
local Cfg = require(Bits:WaitForChild("Cfg"))
local Fmt = require(Bits:WaitForChild("Fmt"))
local List = require(script.Parent.List)
local Gift = require(script.Parent.Gift)
local Store = require(SSS:WaitForChild("Data"):WaitForChild("Store"))
local Hook = require(SSS:WaitForChild("Hooks"):WaitForChild("Hook"))

local Buy = {}

local held: { [Player]: { [string]: boolean } } = {}

local function bag(d: any, name: string): any
	if type(d[name]) ~= "table" then
		d[name] = {}
	end
	return d[name]
end

function Buy.item(kind: string, key: string): any?
	for _, it in List[kind] or {} do
		if it.key == key then
			return it
		end
	end
	return nil
end

function Buy.byId(kind: string, id: number): any?
	for _, it in List[kind] or {} do
		if it.id == id and id ~= 0 then
			return it
		end
	end
	return nil
end

function Buy.owns(plr: Player, key: string): number
	local d = Store.get(plr)
	if not d or type(d.owns) ~= "table" then
		return 0
	end
	return d.owns[key] or 0
end

function Buy.pass(plr: Player, key: string): boolean
	local it = Buy.item("pass", key)
	if not it or it.id == 0 then
		return false
	end
	local mine = held[plr]
	if not mine then
		mine = {}
		held[plr] = mine
	end
	if mine[key] ~= nil then
		return mine[key]
	end
	local ok, got = pcall(MPS.UserOwnsGamePassAsync, MPS, plr.UserId, it.id)
	mine[key] = ok and got == true
	return mine[key]
end

function Buy.mark(plr: Player, id: number)
	local it = Buy.byId("pass", id)
	if not it then
		return
	end
	local mine = held[plr]
	if not mine then
		mine = {}
		held[plr] = mine
	end
	mine[it.key] = true
	Gift.give(plr, it.key)
	Hook.send("shop", Hook.card("pass bought", Hook.hue.good):who(plr):row("pass", it.name):row("id", id))
end

function Buy.award(plr: Player, n: number): number
	local mult = (plr:GetAttribute("Mult") or 1) :: number
	local amt = math.floor(n * mult)
	local got = Store.bump(plr, "cash", amt)
	if got then
		plr:SetAttribute("Cash", got)
	end
	return amt
end

function Buy.spend(plr: Player, n: number): boolean
	local d = Store.get(plr)
	if not d or d.cash < n then
		return false
	end
	d.cash -= n
	plr:SetAttribute("Cash", d.cash)
	return true
end

function Buy.cash(plr: Player, key: string): (boolean, string)
	local it = Buy.item("cash", key)
	if not it then
		return false, "no item called that"
	end
	local d = Store.get(plr)
	if not d then
		return false, "your save is still loading"
	end
	if it.max > 0 and Buy.owns(plr, key) >= it.max then
		return false, "you own that already"
	end
	if d.cash < it.cost then
		return false, string.format("you need %s more cash", Fmt.num(it.cost - d.cash))
	end
	Buy.spend(plr, it.cost)
	bag(d, "owns")[key] = Buy.owns(plr, key) + 1
	Gift.give(plr, key)
	Hook.send("shop", Hook.card("shop buy", Hook.hue.info)
		:who(plr)
		:row("item", it.name)
		:row("cost", Fmt.num(it.cost))
		:row("left", Fmt.num(d.cash)))
	return true, "bought " .. it.name
end

function Buy.free(plr: Player, key: string): (boolean, string)
	local it = Buy.item("cash", key) or Buy.item("pass", key)
	if not it then
		return false, "no item called that"
	end
	local d = Store.get(plr)
	if d and Buy.item("cash", key) then
		bag(d, "owns")[key] = Buy.owns(plr, key) + 1
	end
	Gift.give(plr, key)
	return true, string.format("%s got %s", plr.Name, it.name)
end

function Buy.redo(plr: Player)
	local d = Store.wait(plr, 15)
	if not d or plr.Parent == nil then
		return
	end
	for _, it in List.cash do
		if it.keep and Buy.owns(plr, it.key) > 0 then
			Gift.give(plr, it.key)
		end
	end
	for _, it in List.pass do
		if it.id ~= 0 and Buy.pass(plr, it.key) then
			Gift.give(plr, it.key)
		end
	end
end

function Buy.menu(plr: Player): any
	local out = { cash = {}, pass = {}, prod = {}, purse = 0 }
	local d = Store.get(plr)
	out.purse = if d then d.cash else 0
	for _, it in List.cash do
		table.insert(out.cash, {
			key = it.key,
			name = it.name,
			info = it.info,
			cost = it.cost,
			max = it.max,
			own = Buy.owns(plr, it.key),
		})
	end
	for _, it in List.pass do
		if it.id ~= 0 then
			table.insert(out.pass, {
				key = it.key,
				name = it.name,
				info = it.info,
				id = it.id,
				own = Buy.pass(plr, it.key),
			})
		end
	end
	for _, it in List.prod do
		if it.id ~= 0 then
			table.insert(out.prod, {
				key = it.key,
				name = it.name,
				info = if it.cash > 0 then Fmt.num(it.cash) .. " cash" else "one use",
				id = it.id,
			})
		end
	end
	return out
end

function Buy.receipt(info: any): Enum.ProductPurchaseDecision
	local keep = Enum.ProductPurchaseDecision.NotProcessedYet
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	if not plr then
		return keep
	end
	local it = Buy.byId("prod", info.ProductId)
	if not it then
		warn(string.format("[buy] product %d is not in the list", info.ProductId))
		return keep
	end
	local d = Store.wait(plr, 12)
	if not d then
		return keep
	end
	local stamp = tostring(info.PurchaseId)
	local done = bag(d, "got")
	if done[stamp] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if it.cash > 0 then
		Buy.award(plr, it.cash)
	end
	Gift.give(plr, it.key)
	done[stamp] = os.time()
	local old, oldest = nil, math.huge
	local n = 0
	for id, at in done do
		n += 1
		if at < oldest then
			old, oldest = id, at
		end
	end
	if n > Cfg.shop.keep and old then
		done[old] = nil
	end
	if not Store.save(plr, false) then
		done[stamp] = nil
		return keep
	end
	Hook.send("shop", Hook.card("robux buy", Hook.hue.good)
		:who(plr)
		:row("item", it.name)
		:row("id", info.ProductId)
		:row("spent", string.format("%d robux", info.CurrencySpent or 0)))
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Players.PlayerRemoving:Connect(function(plr)
	held[plr] = nil
end)

return Buy
