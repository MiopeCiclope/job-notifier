local eq = assert.are.same
local neq = assert.are_not.same
local cleanUp = require("job-notifier.test-utils").cleanUp

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
	before_each(function()
		os.remove("test.txt")
	end)
	cleanUp()

	it("it should create file", function()
		local fileBefore = io.open("test.txt", "r")
		eq(fileBefore, nil)

		utils:saveToFile("test.txt", { "test" })

		local fileAfter = io.open("test.txt", "r")
		neq(fileAfter, nil)
	end)
end)
