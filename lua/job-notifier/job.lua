local utils = require("job-notifier.utils")

---@class Job
---@field id number  @A unique identifier for the job
---@field name string  @The name of the job, taken from the meta name
---@field stages table<string, any>  @Merged stages from the class stages and job-specific stages
---@field currentStage string  @The current stage of the job, initialized to "job-start"
---@field logFile string  @The log file associated with the job, from the meta data
---@field output table<number, any>  @A list of output entries, indexed by number
---@field isRunning boolean @Tell is this specific job is running or not
local Job = {}
Job.__index = Job

---Constructor for Job
---@param meta Meta  @The metadata of a job
---@param defaultStages table<string, string> @The stages that all jobs should have
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
	self.isRunning = false
	return self
end

---Reads job log and look for stage matching
---@param data table<any, string>  @The output of an executing job
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
	utils:saveToFile(self:getLogPath(), output_data)
end

function Job:getLogPath()
	local dataDir = vim.fn.stdpath("data")
	return dataDir .. "/" .. self.name
end

return Job
