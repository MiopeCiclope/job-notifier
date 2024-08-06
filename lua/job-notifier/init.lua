local M = {
	job_id = nil,
	state = nil,
}

-- Table to store the job ID and output
local output = {}
local output_file = "jobOutput.txt" -- Specify your desired output file path
local patterns = {
	["default"] = {
		state = 1,
		display_text = "Job Started",
	},
	["Compiling"] = {
		state = 2,
		display_text = "Building",
	},

	["No issues found"] = {
		state = 2,
		display_text = "Build Successful",
	},
}

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
	print("Starting script")
	M.state = patterns["default"]
	-- Function to handle output
	local function on_output(id, data, event)
		for _, line in ipairs(data) do
			for pattern, value in pairs(patterns) do
				if string.match(line, pattern) then
					M.state = value
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
			-- Write any remaining output to the file
			write_output_to_file()
			M.job_id = nil
			print("Job completed and output saved to file")
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
	return M.state.display_text
end

return M
