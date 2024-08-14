local eq = assert.are.same
local awaitEqual = require("job-notifier.test-utils").awaitUntilEqual
local cleanUp = require("job-notifier.test-utils").cleanUp

local scanner = require("job-notifier")
local opt_meta = {
	{
		name = "test",
		cmd = "echo test",
		log_file = "test.txt",
		stages = {
			["test"] = {
				text = "running",
				color = "red",
			},
		},
	},
}

describe("Setup", function()
	before_each(function()
		scanner = require("job-notifier")
	end)

	it("should setup with no parameters", function()
		scanner.setup()

		eq({}, scanner.meta)
		eq({
			["job-start"] = { text = "Job Started", color = "black" },
			["job-done"] = { text = "Job finished", color = "black" },
		}, scanner.stages)
	end)

	it("should store job metadata", function()
		scanner.setup({
			meta = opt_meta,
		})

		eq(opt_meta, scanner.meta)
	end)

	cleanUp()
end)

describe("Start", function()
	before_each(function()
		scanner = require("job-notifier")
		scanner.setup(opt_meta)
	end)

	it("should't run if no job found", function()
		eq({}, scanner.jobs)
		scanner.run("fail")

		eq({}, scanner.jobs)
	end)

	it("should run command", function()
		eq({}, scanner.jobs)
		scanner.run("test")

		eq("test", scanner.jobs[1].name)
		eq("job-start", scanner.jobs[1].current_stage)
	end)

	cleanUp()
end)

describe("Scan job", function()
	before_each(function()
		scanner = require("job-notifier")
		scanner.setup(opt_meta)
		scanner.run("test")
	end)

	it("should keep job stage case no keyword is found", function()
		scanner.scan_output(scanner.jobs[1], { "output no keywords" })

		eq(scanner.jobs[1].current_stage, "job-start")
	end)

	it("should change job stage when finds keywords", function()
		scanner.scan_output(scanner.jobs[1], { "output test" })

		eq(scanner.jobs[1].current_stage, "test")
	end)

	cleanUp()
end)

describe("Stop job", function()
	before_each(function()
		scanner = require("job-notifier")
		scanner.setup(opt_meta)
	end)

	it("should stop running job", function()
		scanner.run("test")

		awaitEqual(scanner.jobs[1].current_stage, "test")
		eq(scanner.jobs[1].current_stage, "test")
		scanner.stop_script("test")

		awaitEqual(scanner.jobs[1].current_stage, "job-done")
		eq(scanner.jobs[1].current_stage, "job-done")
	end)

	cleanUp()
end)


