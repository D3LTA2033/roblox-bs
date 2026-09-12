-- made by @mcs.s on discord

local Http = game:GetService("HttpService")
local RepS = game:GetService("ReplicatedStorage")

local Fmt = require(RepS:WaitForChild("Bits"):WaitForChild("Fmt"))
local Keys = require(script.Parent.Keys)
local Que = require(script.Parent.Que)
local Emb = require(script.Parent.Emb)

local Hook = {}

Hook.hue = Emb.hue

local lanes: { [string]: { line: Que.Que, awake: boolean } } = {}
local moaned = false

local function live(): boolean
	if Http.HttpEnabled then
		return true
	end
	if not moaned then
		moaned = true
		warn("[hook] http requests are off, turn them on in game settings")
	end
	return false
end

local function link(tag: string): string?
	local url = Keys[tag]
	if type(url) ~= "string" or url == "" then
		url = Keys.main
	end
	if type(url) ~= "string" or url == "" then
		return nil
	end
	if Keys.proxy ~= "" and string.find(url, "discord.com", 1, true) then
		url = string.gsub(url, "^https://discord%.com/api/webhooks", Keys.proxy)
	end
	return url
end

local function shoot(url: string, body: any): (boolean, number, any)
	local res
	local ok, err = pcall(function()
		res = Http:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = Http:JSONEncode(body),
		})
	end)
	if not ok then
		return false, 0, tostring(err)
	end
	if res.Success then
		return true, res.StatusCode, nil
	end
	if res.StatusCode == 429 then
		local nap = 1.5
		local fine, back = pcall(Http.JSONDecode, Http, res.Body)
		if fine and type(back) == "table" and tonumber(back.retry_after) then
			nap = tonumber(back.retry_after) :: number
			if nap > 60 then
				nap /= 1000
			end
		end
		return false, 429, math.clamp(nap, 0.5, 20)
	end
	return false, res.StatusCode, Fmt.cut(res.Body, 200)
end

local function pack(load: { any }): any
	local body = { username = Keys.who, allowed_mentions = { parse = {} }, embeds = {} }
	for _, item in load do
		if type(item) == "string" then
			body.content = if body.content then body.content .. "\n" .. item else item
		else
			table.insert(body.embeds, item)
		end
	end
	if body.content then
		body.content = Fmt.cut(body.content, 1900)
	end
	if #body.embeds == 0 then
		body.embeds = nil
	end
	return body
end

local function pump(tag: string, url: string)
	local lane = lanes[tag]
	while lane.line:size() > 0 do
		local load = lane.line:take(10)
		local won, code, extra = shoot(url, pack(load))
		if not won then
			if code == 429 then
				for i = #load, 1, -1 do
					lane.line:front(load[i])
				end
				task.wait(if type(extra) == "number" then extra else 2)
			elseif code >= 500 or code == 0 then
				for i = #load, 1, -1 do
					lane.line:front(load[i])
				end
				task.wait(5)
			else
				warn(string.format("[hook] %s dropped %d items, code %d (%s)", tag, #load, code, tostring(extra)))
			end
		end
		task.wait(1.2)
	end
	lane.awake = false
end

local function queue(tag: string, item: any)
	if not live() then
		return
	end
	local url = link(tag)
	if not url then
		return
	end
	local lane = lanes[tag]
	if not lane then
		lane = { line = Que.new(250), awake = false }
		lanes[tag] = lane
	end
	lane.line:push(item)
	if not lane.awake then
		lane.awake = true
		task.spawn(pump, tag, url)
	end
end

function Hook.card(title: string, hue: number?)
	return Emb.new(title, hue)
end

function Hook.send(tag: string, card: any)
	queue(tag, if type(card) == "table" and card.out then card:out() else card)
end

function Hook.text(tag: string, body: string)
	queue(tag, Fmt.cut(body, 1900))
end

function Hook.now(tag: string, body: string): boolean
	if not live() then
		return false
	end
	local url = link(tag)
	if not url then
		return false
	end
	local won = shoot(url, pack({ Fmt.cut(body, 1900) }))
	return won
end

return Hook
