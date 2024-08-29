local eq = assert.are.same
local cleanUp = require("job-notifier.test-utils").cleanUp

local Job = require("job-notifier.job")
local meta = {
	name = "test",
	cmd = "echo test",
	logFile = "test.txt",
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
	before_each(function()
		job = Job.new(meta, defaultStages)
	end)

	it("should keep job stage case no keyword is found", function()
		job:handleOutput({ "output no keywords" })

		eq(job.currentStage, "job-start")
	end)

	it("should change job stage when finds keywords", function()
		job:handleOutput({ "output test" })

		eq(job.currentStage, "test")
	end)

	cleanUp()
end)
