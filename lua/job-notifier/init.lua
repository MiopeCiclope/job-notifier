local M = {
	job_id = nil,
	state = "idle",
	patterns = {
		["idle"] = "No job running",
		["start"] = "Job Started",
	},
}

-- Table to store the job ID and output
local output = {}
local output_file = "jobOutput.txt" -- Specify your desired output file path

-- Function to write output to the file
local function write_output_to_file()
	local file = io.open(output_file, "a")
	if file then
		for _, line in ipairs(output) do
			file:write(line .. "\n")
		end
		file:close()
	end
	output = {}
end

-- Function to run the script and capture output
M.run = function(cmd)
	M.state = "start"
	local function on_output(id, data, event)
		for _, line in ipairs(data) do
			for pattern, _ in pairs(M.patterns) do
				if string.match(line, pattern) then
					M.state = pattern
					break
				end
			end

			if line ~= "" then
				table.insert(output, line)
				if #output >= 100 then
					write_output_to_file()
				end
			end
		end
	end

	-- Start the job
	M.job_id = vim.fn.jobstart(cmd, {
		on_stdout = on_output,
		on_stderr = on_output,
		on_exit = function()
			write_output_to_file()
			M.job_id = nil
      M.state = "idle"
		end,
	})
end

-- Function to stop the running job
M.stop_script = function()
	if M.job_id then
		vim.fn.jobstop(M.job_id)
		write_output_to_file() -- Write remaining output before stopping the job
		M.job_id = nil
		print("Job stopped and output saved to file")
	else
		print("No job running")
	end
end

-- Function to open the output file in a new buffer
M.open_output_file = function()
	vim.api.nvim_command("edit " .. output_file)
end

M.getState = function()
	if M.state ~= nil then
		return M.patterns[M.state]
	end
end

M.setup = function(opts)
	if opts.patterns ~= nil then
		for key, value in pairs(opts.patterns) do
			M.patterns[key] = value
		end
	end
end

return M
