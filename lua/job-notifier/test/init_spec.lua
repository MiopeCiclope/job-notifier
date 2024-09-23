local eq = assert.are.same
local awaitEqual = require("job-notifier.test-utils").awaitUntilEqual
local setupDirMock = require("job-notifier.test-utils").setupDirMock
local cleanUpDirMock = require("job-notifier.test-utils").cleanUpDirMock
local setupFileMock = require("job-notifier.test-utils").setupFileMock
local cleanUpFileMock = require("job-notifier.test-utils").cleanUpFileMock

local mock = require("luassert.mock")
local scanner = require("job-notifier")
local opt_meta = {
	{
		name = "test",
		cmd = "echo test",
		stages = {
			["test"] = {
				text = "running",
				color = "red",
			},
		},
	},
}

describe("Setup", function()
	local mockFile, mockIo
	local fn

	before_each(function()
		mockFile, mockIo = setupFileMock()
		fn = setupDirMock()

		scanner = require("job-notifier")
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
	end)

	it("should setup with no parameters", function()
		scanner:setup()

		eq({}, scanner.meta)
		eq({
			["job-start"] = { text = "Job Started", color = "black" },
			["job-done"] = { text = "Job finished", color = "black" },
		}, scanner.stages)
	end)

	it("should store job metadata", function()
		scanner:setup({
			meta = opt_meta,
		})

		eq(opt_meta, scanner.meta)
	end)
end)

describe("Start", function()
	local mockFile, mockIo
	local fn

	before_each(function()
		mockFile, mockIo = setupFileMock()
		fn = setupDirMock()

		scanner = require("job-notifier")
		scanner:setup(opt_meta)
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
	end)

	it("should't run if no job found", function()
		eq({}, scanner.jobs)
		scanner:run("fail")

		eq({}, scanner.jobs)
	end)

	it("should run command", function()
		eq({}, scanner.jobs)
		scanner:run("test")

		eq("test", scanner.jobs[1].name)
		eq("job-start", scanner.jobs[1].currentStage)
	end)
end)

describe("Scan job", function()
	local mockFile, mockIo
	local fn

	before_each(function()
		mockFile, mockIo = setupFileMock()
		fn = setupDirMock()

		scanner = require("job-notifier")
		scanner:setup(opt_meta)
		scanner:run("test")
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
	end)

	it("should keep job stage case no keyword is found", function()
		scanner.jobs[1]:handleOutput({ "output no keywords" })

		eq(scanner.jobs[1].currentStage, "job-start")
	end)

	it("should change job stage when finds keywords", function()
		scanner.jobs[1]:handleOutput({ "output test" })

		eq(scanner.jobs[1].currentStage, "test")
	end)
end)

describe("Stop job", function()
	local mockFile, mockIo
	local fn

	before_each(function()
		mockFile, mockIo = setupFileMock()
		fn = setupDirMock()

		scanner = require("job-notifier")
		scanner:setup(opt_meta)
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
	end)

	it("should stop running job", function()
		scanner:run("test")
		scanner.jobs[1]:handleOutput({ "output test" })

		eq(scanner.jobs[1].currentStage, "test")
		scanner:stop("test")

		awaitEqual(scanner.jobs[1].currentStage, "job-done")
		eq(scanner.jobs[1].currentStage, "job-done")
	end)
end)

describe("Create Job", function()
	local mockFile, mockIo
	local fn

	before_each(function()
		mockFile, mockIo = setupFileMock()
		fn = setupDirMock()
		fn.jobstart = mock(vim.fn.jobstart, true)

		scanner = require("job-notifier")
		scanner:setup(opt_meta)
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
	end)

	it("should start a background job", function()
		scanner:createJob(opt_meta, scanner.jobs[1], function() end)

		assert.stub(fn.jobstart).was_called(1)
	end)
end)

describe("Show Logs", function()
	local mockFile, mockIo
	local fn
	local mockVimApi

	before_each(function()
		mockFile, mockIo = setupFileMock()
		mockVimApi = vim.api

		fn = setupDirMock()
		mockVimApi.nvim_command = mock(vim.api.nvim_command, true)

		scanner = require("job-notifier")
		scanner:setup(opt_meta)
	end)

	after_each(function()
		cleanUpFileMock(mockFile, mockIo)
		cleanUpDirMock(fn)
		mockVimApi.nvim_command:revert()
	end)

	it("should not open log when job not found", function()
		local jobName = "fail"

		scanner:showLog(jobName)
		assert.stub(mockVimApi.nvim_command).was_called(0)
	end)

	it("should show log of running job", function()
		local jobName = "test"

		scanner:showLog(jobName)
		assert.stub(mockVimApi.nvim_command).was_called(0)

		scanner:run(jobName)
		scanner:showLog(jobName)
		assert.stub(mockVimApi.nvim_command).was_called(1)
		assert.stub(mockVimApi.nvim_command).was_called_with("edit root/job-scanner/test/test.log")
	end)
end)
