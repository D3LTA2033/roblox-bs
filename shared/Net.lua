-- made by @mcs.s on discord

local RepS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")

local Net = {}

local live = Run:IsServer()
local box: Instance? = nil

local function root(): Instance
	if box then
		return box
	end
	if live then
		local found = RepS:FindFirstChild("Wire")
		if not found then
			found = Instance.new("Folder")
			found.Name = "Wire"
			found.Parent = RepS
		end
		box = found
	else
		box = RepS:WaitForChild("Wire", 30)
		if not box then
			error("Wire folder never showed up, is the server code in?", 0)
		end
	end
	return box :: Instance
end

local function grab(name: string, kind: string): any
	local host = root()
	local found = host:FindFirstChild(name)
	if found then
		return found
	end
	if not live then
		found = host:WaitForChild(name, 30)
		if not found then
			error(string.format("missing remote %q", name), 0)
		end
		return found
	end
	local made = Instance.new(kind)
	made.Name = name
	made.Parent = host
	return made
end

function Net.ev(name: string): RemoteEvent
	return grab(name, "RemoteEvent")
end

function Net.fn(name: string): RemoteFunction
	return grab(name, "RemoteFunction")
end

return Net
