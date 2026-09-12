-- made by @mcs.s on discord

local Bin = {}
Bin.__index = Bin

export type Bin = typeof(setmetatable({} :: { jobs: { any } }, Bin))

function Bin.new(): Bin
	return setmetatable({ jobs = {} }, Bin)
end

function Bin:add<T>(job: T): T
	table.insert(self.jobs, job)
	return job
end

function Bin:tie(inst: Instance)
	self:add(inst.Destroying:Connect(function()
		self:wipe()
	end))
end

function Bin:wipe()
	local jobs = self.jobs
	for i = #jobs, 1, -1 do
		local job = jobs[i]
		jobs[i] = nil
		local kind = typeof(job)
		if kind == "RBXScriptConnection" then
			job:Disconnect()
		elseif kind == "Instance" then
			job:Destroy()
		elseif kind == "function" then
			task.spawn(job)
		elseif kind == "thread" then
			pcall(task.cancel, job)
		elseif kind == "table" and type(job.wipe) == "function" then
			job:wipe()
		end
	end
end

return Bin
