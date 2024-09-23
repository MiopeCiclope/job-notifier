local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local config = require("telescope.config").values
local actions = require('telescope.actions')
local previewers = require('telescope.previewers')

local M = {}

M.listLogs = function(opts)
  opts = opts or {}
  local dataDir = vim.fn.stdpath("data")
  local formatted_time = os.date("%Y%m%d")

  local file_list = {
    dataDir .. "/job-scanner/build/" .. formatted_time .. ".log",
    dataDir .. "/job-scanner/watcher/" .. formatted_time .. ".log",
    dataDir .. "/job-scanner/react/" .. formatted_time .. ".log",
  }

  pickers.new(opts, {
    prompt_title = "Static File List with Preview",
    finder = finders.new_table {
      results = file_list
    },
    sorter = config.generic_sorter(opts),

    -- Previewer to show the contents of the selected file
    previewer = previewers.cat.new(opts),

    -- Mappings for selecting an entry
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = actions.get_selected_entry()
        actions.close(prompt_bufnr)
        print("You selected: " .. selection.value)
        -- You can add more logic here, like opening the selected file
      end)
      return true
    end,
  }):find()
end

return M
