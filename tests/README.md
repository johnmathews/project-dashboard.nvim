# Tests

Test suite for project-dashboard.nvim using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

## Prerequisites

Install plenary.nvim:

```lua
-- Using lazy.nvim
{ 'nvim-lua/plenary.nvim' }
```

## Running Tests

### Run all tests
```bash
nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.vim' }"
```

### Run specific test file
```bash
nvim --headless -c "PlenaryBustedFile tests/init_spec.lua"
```

### Run from within Neovim
```vim
:PlenaryBustedDirectory tests/
:PlenaryBustedFile tests/git_spec.lua
```

## Test Files

- **init_spec.lua** - Tests for plugin initialization and setup
- **git_spec.lua** - Tests for Git integration and GitHub remote detection  
- **tiles_spec.lua** - Tests for tile layout calculations

## Writing Tests

Tests follow the [plenary.nvim busted-style](https://github.com/nvim-lua/plenary.nvim#plenarybusted) testing framework:

```lua
describe("module name", function()
  before_each(function()
    -- Setup before each test
  end)

  it("should do something", function()
    assert.are.same(expected, actual)
    assert.is_true(condition)
  end)
end)
```

## CI Integration

GitHub Actions workflow example:

```yaml
- name: Run tests
  run: |
    nvim --headless -c "PlenaryBustedDirectory tests/"
```
