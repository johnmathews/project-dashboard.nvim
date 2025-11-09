.PHONY: test test-init test-git test-tiles

# Run all tests with minimal config (avoids loading user's init.lua)
test:
	@echo "Running all tests..."
	@nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedDirectory tests/" -c "quit"

# Run specific test files
test-init:
	@echo "Running initialization tests..."
	@nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedFile tests/init_spec.lua" -c "quit"

test-git:
	@echo "Running git tests..."
	@nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedFile tests/git_spec.lua" -c "quit"

test-tiles:
	@echo "Running tiles tests..."
	@nvim --headless -u tests/minimal_init.vim -c "PlenaryBustedFile tests/tiles_spec.lua" -c "quit"
