local utils = require("job-notifier.utils")

---@class Meta
---@field name string  @The name of the project or process
---@field cmd string  @The command to run the process
---@field logFile string  @The file where the log is stored
---@field stages table<string, any>  @The stages with keys like "Compiling" and corresponding stage information

---@class Job
---@field id number  @A unique identifier for the job
---@field name string  @The name of the job, taken from the meta name
---@field stages table<string, any>  @Merged stages from the class stages and job-specific stages
---@field currentStage string  @The current stage of the job, initialized to "job-start"
---@field logFile string  @The log file associated with the job, from the meta data
---@field output table<number, any>  @A list of output entries, indexed by number
local Job = {}
Job.__index = Job

---Constructor for Job
---@return Job  @Returns a new instance of the class Scanner
function Job.new(meta, defaultStages)
	---@type Job
	local self = setmetatable({}, Job)

	self.id = 0
	self.name = meta.name
	self.stages = utils:mergeStages(defaultStages, meta.stages)
	self.currentStage = "job-start"
	self.logFile = meta.logFile
	self.output = {}
	return self
end

function Job:handleOutput(data)
	local output_data = {}
	for _, line in ipairs(data) do
		table.insert(output_data, line)
		for key, _ in pairs(self.stages) do
			if string.match(line, key) then
				self.currentStage = key
				break
			end
		end
	end
	utils:saveToFile(self.logFile, output_data)
end

---@class Scanner
---@field jobs table<number, Job>  @A list of jobs, indexed by a number
---@field meta table<string, Job>  @A list of jobs, indexed by a number
---@field stages table<string, any>  @Stages with string keys, each having a table with text and color
local Scanner = {}
Scanner.__index = Scanner

---Constructor for M
---@return Scanner  @Returns a new instance of the class Scanner
function Scanner.new()
	---@type Scanner
	local self = setmetatable({}, Scanner)

	self.jobs = {} ---@type table<number, Job>
	self.meta = {} ---@type table<string, Meta>
	self.stages = { ---@type table<string, any>
		["job-start"] = { text = "Job Started", color = "black" },
		["job-done"] = { text = "Job finished", color = "black" },
	}

	return self
end

---Adds a job to the jobs list
---@param job Job  @The job to be added
function Scanner:addJob(job)
	table.insert(self.jobs, job)
end

-- Function to run the script and capture output
---@param metaName string
function Scanner:run(metaName)
	local meta = utils:findByName(self.meta, metaName)
	if meta == nil then
		print("No job details not found for: " .. metaName)
		return
	end

	self:addJob(Job.new(meta, self.stages))
	local index = #self.jobs

	-- Start the job
	self.jobs[index].id = vim.fn.jobstart(meta.cmd, {
		on_stdout = function(id, data, event)
			self.jobs[index]:handleOutput(data)
		end,
		on_stderr = function(id, data, event)
			self.jobs[index]:handleOutput(data)
		end,
		on_exit = function()
			self.jobs[index].currentStage = "job-done"
		end,
	})
end

-- Function to stop the running job
function Scanner:stop(jobName)
	local job = utils:findByName(self.jobs, jobName)
	if job then
		vim.fn.jobstop(job.id)
		job.stage = "job-done"
		print("Job stopped and output saved to file")
	else
		print("No job running")
	end
end

-- Function to open the output file in a new buffer
function Scanner:showLog(jobName)
	local job = utils:findByName(self.jobs, jobName)
	if job then
		vim.api.nvim_command("edit " .. job.logFile)
	else
		print("No job: " .. jobName)
	end
end

function Scanner:getState(jobName)
	local job = utils:findByName(self.jobs, jobName)

	if job then
		return job.stages[job.currentStage].text
	end
	return nil
end

function Scanner:getColor(jobName)
	local job = utils:findByName(self.jobs, jobName)
	if job then
		return job.stages[job.currentStage].color
	end
	return nil
end

local scanner = Scanner.new()

function Scanner.setup(self, opts)
	if self ~= scanner then
		self = scanner
	end

	if opts ~= nil and opts.meta ~= nil then
		self.meta = opts.meta
	end
end

return scanner
