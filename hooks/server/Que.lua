-- made by @mcs.s on discord

local Que = {}
Que.__index = Que

export type Que = typeof(setmetatable({} :: { cap: number, lost: number, items: { any } }, Que))

function Que.new(cap: number?): Que
	return setmetatable({ cap = cap or 200, lost = 0, items = {} }, Que)
end

function Que:push(item: any)
	local items = self.items
	if #items >= self.cap then
		table.remove(items, 1)
		self.lost += 1
	end
	table.insert(items, item)
end

function Que:front(item: any)
	table.insert(self.items, 1, item)
end

function Que:take(n: number): { any }
	local out = {}
	for _ = 1, n do
		local got = table.remove(self.items, 1)
		if got == nil then
			break
		end
		table.insert(out, got)
	end
	return out
end

function Que:size(): number
	return #self.items
end

return Que
