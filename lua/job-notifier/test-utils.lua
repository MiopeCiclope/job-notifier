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

---Mock functions related to create files
M.setupDirMock = function()
	local fn = vim.fn
	fn.fnamemodify = mock(vim.fn.fnamemodify, true)
	fn.isdirectory = mock(vim.fn.isdirectory, true)
	fn.mkdir = mock(function(path, opts) end)

	return fn
end

---Remove mocked dir functions
---@param fn any
M.cleanUpDirMock = function(fn)
	fn.fnamemodify:revert()
	fn.isdirectory:revert()
	fn.mkdir:revert()
end

---Mock file creation
M.setupFileMock = function()
	local mockFile, mockIo
	mockFile = {
		write = function() end,
		close = function() end,
	}

	mockIo = mock(io, true)
	mockIo.open.returns(mockFile)

	mockFile.write = mock(mockFile.write, true)
	mockFile.close = mock(mockFile.close, true)
	return mockFile, mockIo
end

---Clean up mock file creation functions
---@param mockFile any
---@param mockIo any
M.cleanUpFileMock = function(mockFile, mockIo)
	mockIo.open:revert()
	mockFile.write:revert()
	mockFile.close:revert()
end

return M
