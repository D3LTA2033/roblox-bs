-- made by @mcs.s on discord

local Players = game:GetService("Players")

local Mute = {}

local gags: { [number]: { till: number, by: string } } = {}

function Mute.add(id: number, secs: number, by: string)
	gags[id] = { till = if secs and secs > 0 then os.time() + secs else -1, by = by }
end

function Mute.drop(id: number)
	gags[id] = nil
end

function Mute.on(id: number): boolean
	local got = gags[id]
	if not got then
		return false
	end
	if got.till > 0 and os.time() >= got.till then
		gags[id] = nil
		return false
	end
	return true
end

function Mute.left(id: number): number
	local got = gags[id]
	if not got then
		return 0
	end
	return if got.till < 0 then -1 else math.max(0, got.till - os.time())
end

Players.PlayerRemoving:Connect(function(plr)
	if gags[plr.UserId] and gags[plr.UserId].till < 0 then
		return
	end
	gags[plr.UserId] = nil
end)

return Mute
