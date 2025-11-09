# project-dashboard.nvim

A modern neovim dashboard plugin that displays project statistics and insights when you open a git repository.

## Features

- 📊 Project statistics (file count, lines of code by language)
- 🌿 Git insights (commits, branches, contributors, remotes)
- 🐙 GitHub data (stars, forks) - public API + fallback scraping
- 🎨 Rich visualizations with performance tracking
- ⚡ Auto-trigger on project open or manual command

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'your-username/project-dashboard.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
  },
  config = function()
    require('project-dashboard').setup()
  end
}
```

## Usage

The dashboard automatically opens when you enter a git repository without specifying a file. You can also manually open it with:

```vim
:ProjectDashboard
```

## Configuration

```lua
require('project-dashboard').setup({
  -- Configuration options coming soon
})
```

## License

MIT