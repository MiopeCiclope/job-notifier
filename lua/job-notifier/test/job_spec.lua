local eq = assert.are.same
local Job = require("job-notifier.job")
local setupDirMock = require("job-notifier.test-utils").setupDirMock
local cleanUpDirMock = require("job-notifier.test-utils").cleanUpDirMock
local setupFileMock = require("job-notifier.test-utils").setupFileMock
local cleanUpFileMock = require("job-notifier.test-utils").cleanUpFileMock

local mock = require("luassert.mock")
local utils = require("job-notifier.utils")

local meta = {
	name = "test",
	cmd = "echo test",
	stages = {
		["test"] = {
			text = "running",
			color = "red",
		},
	},
}

local defaultStages = {
	["job-start"] = { text = "Job Started", color = "black" },
	["job-done"] = { text = "Job finished", color = "black" },
}

local job = Job.new(meta, defaultStages)

describe("Job", function()
	local mockFile, mockIo
	local fn

	before_each(function()
		job = Job.new(meta, defaultStages)
		mockFile, mockIo = setupFileMock()
		fn = setupDirMock()
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
	end)

	it("should keep job stage case no keyword is found", function()
		job:handleOutput({ "output no keywords" })

		eq(job.currentStage, "job-start")
	end)

	it("should change job stage when finds keywords", function()
		job:handleOutput({ "output test" })

		eq(job.currentStage, "test")
	end)

	it("should create log file", function()
		local utilsMock
		utilsMock = mock(utils)
		utilsMock.saveToFile = mock(utils.saveToFile, true)

		job:handleOutput({ "output test" })

		assert.stub(utilsMock.saveToFile).was_called(1)
		eq(job.currentStage, "test")
	end)

	it("should return job folder path", function()
		local path = job:getLogPath()
		eq(path, "root/job-scanner/" .. job.name .. "/")
	end)
end)
