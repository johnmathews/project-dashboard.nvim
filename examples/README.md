# Configuration Examples

Example configurations for project-dashboard.nvim.

## Files

- **config.lua** - Comprehensive configuration example with all available options

## Usage

Copy and modify these examples in your Neovim configuration:

```lua
-- In your init.lua or lazy.nvim config
require('project-dashboard').setup({
  layout = {
    margin_x = 12,
    margin_y = 2,
  },
  tiles = {
    gap_x = 4,
    gap_y = 1,
  }
})
```

See [config.lua](./config.lua) for all available options.
