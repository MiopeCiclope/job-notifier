local M = {}

M.awaitUntilEqual = function(a, b)
	local max_retries = 100
	local delay_time = 0.01 -- 10ms
	local retries = 0
	while a ~= b and retries < max_retries do
		vim.wait(delay_time * 1000)
		retries = retries + 1
	end
end

M.cleanUp = function()
	after_each(function()
		os.remove("test.txt")
	end)
end

return M
