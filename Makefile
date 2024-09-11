TEST_FILE ?=lua/job-notifier/test/utils_spec.lua

test:
	nvim --headless --noplugin -u scripts/minimal.vim \
		-c "PlenaryBustedFile $(TEST_FILE)"

test-all:
	nvim --headless --noplugin -u scripts/minimal.vim \
		-c "PlenaryBustedDirectory lua/job-notifier/test/ {minimal_init = 'scripts/minimal.vim'}"

