local M = {}
local mock = require("luassert.mock")

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

---Mock functions related to create files
---@param dirData any
M.mockFileCreation = function(dirData)
	local fn = vim.fn
	dirData.mkdirCalled = false

	before_each(function()
		dirData.mkdirCalled = false
		fn.fnamemodify = mock(vim.fn.fnamemodify, true)
		fn.isdirectory = mock(vim.fn.isdirectory, true)
		fn.mkdir = mock(function(path, opts)
			dirData.mkdirCalled = true
		end)
	end)

	after_each(function()
		mock.revert(fn.fnamemodify)
		mock.revert(fn.isdirectory)
		mock.revert(fn.mkdir)
	end)

	return fn
end

return M
