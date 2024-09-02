local M = {}

---Fetches all possible option of jobs to run
---@param completionList table<string>
---@param argLead string @User cmd input
---@return table<string>?
function M.getCompletion(completionList, argLead)
  local matches = {}
  for _, name in ipairs(completionList) do
    if name:sub(1, #argLead):lower() == argLead:lower() then
      table.insert(matches, name)
    end
  end

  return matches
end

---Create command to run plugin
---@param jobName string
---@param completionList table<string>
---@param job fun(args:string)
function M.createCommand(jobName, completionList, job)
  vim.api.nvim_create_user_command(jobName, function(opts)
    job(opts.args)
  end, {
    nargs = 1,
    complete = function(ArgLead, CmdLine, CursorPos)
      return M.getCompletion(completionList, ArgLead)
    end,
    desc = "Run a job in the background",
  })
end

return M
