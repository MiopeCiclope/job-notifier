test:
	nvim --headless --noplugin -u scripts/minimal.vim \
		-c "PlenaryBustedDirectory lua/job-notifier/test/ {minimal_init = 'scripts/minimal.vim'}"
