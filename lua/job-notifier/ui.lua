local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config").values
local actions = require("telescope.actions")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")

local M = {}

M.listLogs = function(opts)
  opts = opts or {}

  local dataDir = vim.fn.stdpath("data")
  local formatted_time = os.date("%Y%m%d")

  local file_list = {
    dataDir .. "/job-scanner/react/" .. formatted_time .. ".log",
    dataDir .. "/job-scanner/build/" .. formatted_time .. ".log",
    dataDir .. "/job-scanner/watcher/" .. formatted_time .. ".log",
  }

  pickers
      .new(opts, {
        prompt_title = "Log list",
        finder = finders.new_table({
          results = file_list,
        }),
        sorter = config.generic_sorter(opts),

        previewer = previewers.new_termopen_previewer({
          get_command = function(entry)
            return { "sh", "-c", "tail -n 25 " .. entry.value .. " | cat" }
          end,
        }),
        layout_strategy = "vertical",
        layout_config = {
          vertical = {
            preview_height = 0.6,
          },
        },
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            vim.api.nvim_command("edit " .. selection.value)
          end)
          return true
        end,
      })
      :find()
end

return M
