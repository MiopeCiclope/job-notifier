local eq = assert.are.same
local neq = assert.are_not.same

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

local function await_job_status(status)
  local max_retries = 100
  local delay_time = 0.01 -- 10ms
  local retries = 0
  while scanner.jobs[1].current_stage ~= status and retries < max_retries do
    vim.wait(delay_time * 1000) -- wait for the specified time
    retries = retries + 1
  end
end

local function clean_up()
  after_each(function()
    os.remove("test.txt")
  end)
end

describe("findByName", function()
  before_each(function()
    scanner = require("job-notifier")
    array = {
      { name = "1" },
      { name = "2" },
      { name = "3" },
      { name = "4" },
    }
  end)

  it("should return table with a given name", function()
    local found = scanner.findByName(array, "1")
    eq(found, { name = "1" })
  end)

  it("should return null when not found", function()
    local found = scanner.findByName(array, "6")
    eq(found, nil)
  end)
end)

describe("mergeStages", function()
  before_each(function()
    scanner = require("job-notifier")
    stages = {
      ["1"] = { value = "1" },
      ["2"] = { value = "2" },
    }
  end)

  it("should join tables with string as key", function()
    local result = scanner.mergeStages(stages, {
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
    local result = scanner.mergeStages(stages, {
      ["1"] = { value = "4" },
      ["2"] = { value = "3" },
    })

    eq(result, {
      ["1"] = { value = "4" },
      ["2"] = { value = "3" },
    })
  end)

  clean_up()
end)

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

  clean_up()
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

  clean_up()
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

  clean_up()
end)

describe("Stop job", function()
  before_each(function()
    scanner = require("job-notifier")
    scanner.setup(opt_meta)
  end)

  it("should stop running job", function()
    scanner.run("test")

    await_job_status("test")
    eq(scanner.jobs[1].current_stage, "test")
    scanner.stop_script("test")

    await_job_status("job-done")
    eq(scanner.jobs[1].current_stage, "job-done")
  end)

  clean_up()
end)

describe("saveLog", function()
  before_each(function()
    scanner = require("job-notifier")
    os.remove("test.txt")
  end)
  clean_up()

  it("it should create file", function()
    local fileBefore = io.open("test.txt", "r")
    eq(fileBefore, nil)

    scanner.saveLog("test.txt", { "test" })

    local fileAfter = io.open("test.txt", "r")
    neq(fileAfter, nil)
  end)
end)
