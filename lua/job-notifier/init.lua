require("job-notifier.meta")
local utils = require("job-notifier.utils")
local Job = require("job-notifier.job")
local command = require("job-notifier.command")

---@class Scanner
---@field jobs table<number, Job>  @A list of jobs, indexed by a number
---@field meta table<Meta>  @A list of jobs meta data
---@field stages table<string, any>  @Stages with string keys, each having a table with text and color
local Scanner = {}
Scanner.__index = Scanner

---Constructor for Scanner
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

---Starts a backgroud task based on meta parameters
---@param meta Meta
---@param job Job
---@param handler (fun(id:number, data: table))
---@return number @Job id
function Scanner:createJob(meta, job, handler)
  return vim.fn.jobstart(meta.cmd, {
    on_stdout = handler,
    on_stderr = handler,
    on_exit = function()
      job.currentStage = "job-done"
    end,
  })
end

---Run the script and capture output
---@param metaName string
function Scanner:run(metaName)
  ---@type Meta?
  local meta = utils:findByName(self.meta, metaName)
  if meta == nil then
    print("No job details not found for: " .. metaName)
    return
  end

  ---@type Job?
  local job = utils:findByName(self.jobs, metaName)
  if job == nil then
    self:addJob(Job.new(meta, self.stages))
    local index = #self.jobs
    job = self.jobs[index]
  else
    job.currentStage = "job-start"
  end

  ---Handles job output and change stages based on that
  ---@param id number
  ---@param data table
  local function handleJobOutput(id, data)
    job:handleOutput(data)
  end

  utils:createDir(job:getLogPath())
  -- Start the job
  job.id = self:createJob(meta, job, handleJobOutput)
  job.isRunning = true
end

-- Function to stop the running job
---@param jobName string
function Scanner:stop(jobName)
  ---@type Job?
  local job = utils:findByName(self.jobs, jobName)
  if job then
    vim.fn.jobstop(job.id)
    job.currentStage = "job-done"
    job.isRunning = false
    print("Job stopped and output saved to file")
  else
    print("No job running")
  end
end

---Open job output in a new buffer
---@param jobName string
function Scanner:showLog(jobName)
  ---@type Job?
  local job = utils:findByName(self.jobs, jobName)
  if job and job.isRunning then
    local formatted_time = os.date("%Y%m%d")
    vim.api.nvim_command("edit " .. job:getLogPath() .. formatted_time .. ".log")
  else
    print("No job: " .. jobName)
  end
end

---Gets job stage data
---@param jobName string
---@param dataKey string
---@return any @Returns the stage data based on the datakey
function Scanner:getStageData(jobName, dataKey)
  ---@type Job?
  local job = utils:findByName(self.jobs, jobName)

  if job then
    return job.stages[job.currentStage][dataKey]
  end
  return nil
end

local scanner = Scanner.new()

---@param self? Scanner
---@param opts? table
---@field meta Meta
function Scanner.setup(self, opts)
  if self ~= scanner then
    self = scanner
  end

  local metaList = {}
  if opts ~= nil and opts.meta ~= nil then
    self.meta = opts.meta

    for _, meta in ipairs(self.meta) do
      table.insert(metaList, meta.name)
    end
  end

  command.createCommand("RunJob", metaList, function(args)
    self:run(args)
  end)

  command.createCommand("StopJob", metaList, function(args)
    self:stop(args)
  end)

  command.createCommand("LogJob", metaList, function(args)
    self:showLog(args)
  end)

  command.createCommand("RunAll", metaList, function()
    self:run("watcher")
    self:run("react")
  end)

  command.createCommand("StopAll", metaList, function()
    self:stop("watcher")
    self:stop("react")
  end)
end

return scanner
