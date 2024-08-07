local M = {
  jobs = {},
  meta = {},
  stages = {
    ["job-idle"] = "No job running",
    ["job-start"] = "Job Started",
    ["job-done"] = "Job finished",
  },
}

local function findByName(array, name)
  for i = 1, #array do
    if array[i].name == name then
      return array[i]
    end
  end
  return nil
end

-- Function to write output to the file
local function write_output_to_file(job)
  local file = io.open(job.log_file, "a")
  if file then
    for _, line in ipairs(job.output) do
      file:write(line .. "\n")
    end
    file:close()
  end
  job.output = {}
end

local function mergeStages(default_stages, custom_stages)
  local result = default_stages
  for key, value in pairs(custom_stages) do
    result[key] = value
  end
  return result
end

-- Function to run the script and capture output
M.run = function(meta_name)
  local job_meta = findByName(M.meta, meta_name)
  if job_meta == nil then
    print("No job details not found for: " .. meta_name)
    return
  end

  table.insert(M.jobs, {
    id = 0,
    name = job_meta.name,
    stages = mergeStages(M.stages, job_meta.stages),
    current_stage = "job-start",
    log_file = job_meta.log_file,
    output = {},
  })

  local job_index = #M.jobs
  local function on_output(id, data, event)
    for _, line in ipairs(data) do
      for stage, _ in pairs(M.jobs[job_index].stages) do
        if string.match(line, stage) then
          M.jobs[job_index].current_stage = stage
          break
        end
      end

      if line ~= "" then
        table.insert(M.jobs[job_index].output, line)
        if #M.jobs[job_index].output >= 100 then
          write_output_to_file(M.jobs[job_index])
        end
      end
    end
  end

  -- Start the job
  M.jobs[job_index].id = vim.fn.jobstart(job_meta.cmd, {
    on_stdout = on_output,
    on_stderr = on_output,
    on_exit = function()
      write_output_to_file(M.jobs[job_index])
      M.jobs[job_index].current_stage = "job-done"
    end,
  })
end

-- Function to stop the running job
M.stop_script = function(job_name)
  local job = findByName(M.jobs, job_name)
  if job then
    vim.fn.jobstop(job.id)
    write_output_to_file(job)
    job.stage = "job-done"
    print("Job stopped and output saved to file")
  else
    print("No job running")
  end
end

-- Function to open the output file in a new buffer
M.open_output_file = function(job_name)
  local job = findByName(M.jobs, job_name)
  if job then
    vim.api.nvim_command("edit " .. job.log_file)
  else
    print("No job: " .. job_name)
  end
end

M.getState = function(job_name)
  local job = findByName(M.jobs, job_name)

  if job then
    return job.stages[job.current_stage]
  end
  return "nothing..."
end

M.setup = function(opts)
  if opts.meta ~= nil then
    M.meta = opts.meta
  end
end

return M
