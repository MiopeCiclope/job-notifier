local eq = assert.are.same
local setupDirMock = require("job-notifier.test-utils").setupDirMock
local cleanUpDirMock = require("job-notifier.test-utils").cleanUpDirMock
local setupFileMock = require("job-notifier.test-utils").setupFileMock
local cleanUpFileMock = require("job-notifier.test-utils").cleanUpFileMock

-- @type Utils
local utils = require("job-notifier.utils")

describe("findByName", function()
	before_each(function()
		array = {
			{ name = "1" },
			{ name = "2" },
			{ name = "3" },
			{ name = "4" },
		}
	end)

	it("should return table with a given name", function()
		local found = utils:findByName(array, "1")
		eq(found, { name = "1" })
	end)

	it("should return null when not found", function()
		local found = utils:findByName(array, "6")
		eq(found, nil)
	end)
end)

describe("mergeStages", function()
	before_each(function()
		stages = {
			["1"] = { value = "1" },
			["2"] = { value = "2" },
		}
	end)

	it("should join tables with string as key", function()
		local result = utils:mergeStages(stages, {
			["3"] = { value = "3" },
			["4"] = { value = "4" },
		})

		eq(result, {
			["1"] = { value = "1" },
			["2"] = { value = "2" },
			["3"] = { value = "3" },
			["4"] = { value = "4" },
		})
	end)

	it("should replace keys with new ones", function()
		local result = utils:mergeStages(stages, {
			["1"] = { value = "4" },
			["2"] = { value = "3" },
		})

		eq(result, {
			["1"] = { value = "4" },
			["2"] = { value = "3" },
		})
	end)
end)

describe("saveLog", function()
	local mockFile, mockIo

	before_each(function()
		mockFile, mockIo = setupFileMock()
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
	end)

	it("it should create file", function()
		local filename = "test.txt"
		local data = { "line 1", "line 2", "line 3" }

		utils:saveToFile(filename, data)

		assert.stub(mockFile.write).was_called(3)
		assert.stub(mockFile.write).was_called_with(mockFile, "line 1\n")
		assert.stub(mockFile.write).was_called_with(mockFile, "line 2\n")
		assert.stub(mockFile.write).was_called_with(mockFile, "line 3\n")

		assert.stub(mockFile.close).was_called(1)
	end)
end)

describe("createDir", function()
	local fn

	before_each(function()
		fn = setupDirMock()
	end)

	after_each(function()
		cleanUpDirMock(fn)
	end)

	it("should create dir when it doesn't exist", function()
		fn.fnamemodify.returns("/path")
		fn.isdirectory.returns(0)

		utils:createDir("/path/file.txt")

		assert.stub(fn.fnamemodify).was_called_with("/path/file.txt", ":h")
		assert.stub(fn.isdirectory).was_called_with("/path")
		assert.stub(fn.mkdir).was_called_with("/path", "p")
	end)

	it("should NOT create dir when it exist", function()
		fn.fnamemodify.returns("/path")
		fn.isdirectory.returns(1)

		utils:createDir("/path/file.txt")

		assert.stub(fn.fnamemodify).was_called_with("/path/file.txt", ":h")
		assert.stub(fn.isdirectory).was_called_with("/path")
	end)
end)
