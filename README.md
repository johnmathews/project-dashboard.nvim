# project-dashboard.nvim

A modern Neovim dashboard plugin that displays comprehensive project statistics and insights when you open a git repository.

## ✨ Features

- **📊 Project Statistics** - File counts, lines of code by language, comprehensive project metrics
- **🌿 Git Insights** - Total commits, branches, remotes, and repository status
- **👥 Contributors** - Top contributors with commit counts
- **🐙 GitHub Integration** - Stars, forks, open issues, and repository metadata (via GitHub API)
- **🎨 Modern UI** - Clean tiled layout with bordered panels and Unicode icons
- **⚡ Performance** - Async data loading with performance tracking
- **🔧 Highly Configurable** - Customize layout, spacing, tiles, and behavior
- **🚀 Auto-trigger** - Automatically opens when entering a git repository

## 📦 Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'johnmathews/project-dashboard.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'  -- optional, for file icons
  },
  config = function()
    require('project-dashboard').setup({})
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'johnmathews/project-dashboard.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
  },
  config = function()
    require('project-dashboard').setup({})
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-tree/nvim-web-devicons'  " optional
Plug 'johnmathews/project-dashboard.nvim'

" In your init.vim or after/plugin/dashboard.lua:
lua require('project-dashboard').setup({})
```

## 🚀 Usage

### Automatic Opening

The dashboard automatically opens when you:
- Open Neovim in a git repository directory without specifying a file
- Navigate to a git repository with `:cd /path/to/repo`

### Manual Opening

Open the dashboard anytime with:

```vim
:ProjectDashboard
```

### Keybindings

When the dashboard is open:
- `q` - Close dashboard
- Any file navigation key - Dashboard auto-closes when you open a file

## ⚙️ Configuration

### Minimal Configuration

```lua
require('project-dashboard').setup({})
```

### Full Configuration (with defaults)

```lua
require('project-dashboard').setup({
  -- Auto-open dashboard when entering a git repository
  auto_open = true,
  
  -- Show performance timing in the command line
  show_timing = true,
  
  -- Conservative auto-open behavior
  -- Won't open if files are specified or session is being loaded
  auto_open_conservative = true,
  
  -- Layout configuration
  layout = {
    margin_x = 8,  -- horizontal margin from screen edges
    margin_y = 1,  -- vertical margin from top/bottom
  },
  
  -- GitHub API integration
  github = {
    enabled = true,
    timeout = 5000,  -- timeout in milliseconds
  },
  
  -- Tile configuration
  tiles = {
    enabled = true,
    
    -- Tile dimensions
    width = 45,   -- minimum tile width (tiles expand to fill space)
    height = 12,  -- tile height in lines
    
    -- Spacing between tiles
    gap_x = 3,  -- horizontal gap between tiles
    gap_y = 1,  -- vertical gap between rows
  }
})
```

### Common Customizations

#### Wider margins for more padding

```lua
require('project-dashboard').setup({
  layout = {
    margin_x = 15,  -- more horizontal padding
    margin_y = 3,   -- more vertical padding
  }
})
```

#### Tighter tile spacing

```lua
require('project-dashboard').setup({
  tiles = {
    gap_x = 2,  -- less horizontal spacing
    gap_y = 0,  -- no vertical spacing between rows
  }
})
```

#### Disable auto-open

```lua
require('project-dashboard').setup({
  auto_open = false
})
-- Then manually open with :ProjectDashboard
```

#### Disable GitHub API (faster loading, no internet required)

```lua
require('project-dashboard').setup({
  github = {
    enabled = false
  }
})
```

## 📊 What Information is Displayed?

### 📁 Project Info
- Project name
- Current git branch
- Remote repository URL

### 📄 File Statistics
- Total files in the project
- Total lines of code
- Breakdown by language with percentages

### 💻 Languages
- Top programming languages by line count
- Visual bar charts showing percentage
- File counts per language

### 🌿 Git Statistics
- Total commits
- Number of branches
- Number of remotes

### 👥 Top Contributors
- Top 5 contributors by commit count
- Name and commit count for each

### 🐙 GitHub Information (if remote is GitHub)
- ⭐ Stars
- 🍴 Forks
- 🐛 Open issues
- 💻 Primary language
- 📝 Repository description

## 🧪 Testing

This plugin includes a comprehensive test suite using [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

### Run all tests

```bash
make test
```

### Run specific test suites

```bash
make test-init        # Test plugin initialization
make test-git         # Test git functionality
make test-tiles       # Test tile layout
```

### Manual testing

```bash
# Test dashboard in headless mode
nvim --headless -c "lua require('project-dashboard').setup({})" -c "ProjectDashboard" -c "sleep 3" -c "qa"
```

## 🔧 Development

See [AGENTS.md](AGENTS.md) for development guidelines and code style conventions.

### Project Structure

```
project-dashboard.nvim/
├── lua/project-dashboard/
│   ├── init.lua           # Main plugin entry point
│   ├── dashboard.lua      # Dashboard rendering and UI
│   ├── git.lua            # Git and GitHub integration
│   ├── stats.lua          # File statistics and analysis
│   └── tiles.lua          # Tile layout system
├── plugin/                # Neovim plugin loader
├── tests/                 # Test suite (plenary.nvim)
├── examples/              # Configuration examples
└── docs/                  # Additional documentation
```

## 🐛 Troubleshooting

### Dashboard doesn't auto-open

- Check that you're in a git repository: `git status`
- Verify `auto_open = true` in your config
- Try manually opening with `:ProjectDashboard`

### GitHub data shows "Unable to fetch"

- Check internet connection
- Verify the remote URL is a GitHub repository: `git remote -v`
- Check GitHub API rate limits (60 requests/hour for unauthenticated)
- Try disabling and re-enabling: `:lua require('project-dashboard').setup({ github = { enabled = false }})`

### Contributors not showing

This should be fixed in the latest version. If you still see "No contributors":
- Verify you have commits: `git log`
- Try running manually: `git shortlog -sn --all`
- Check Neovim messages: `:messages`

### Performance issues on large repositories

- Disable GitHub API for faster loading: `github = { enabled = false }`
- The plugin uses async loading and should handle large repos well
- Check performance timing with `show_timing = true`

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

### Areas for contribution

- Additional tile types (tests, CI status, etc.)
- Support for other git hosting services (GitLab, Bitbucket)
- Custom tile ordering and layout
- Theme/color customization
- Performance optimizations

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- Inspired by other dashboard plugins like [alpha.nvim](https://github.com/goolord/alpha-nvim) and [dashboard-nvim](https://github.com/nvimdev/dashboard-nvim)
- Built with [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) for async operations
- Uses [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) for file icons

## 📬 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/johnmathews/project-dashboard.nvim/issues)
- 💡 **Feature Requests**: [GitHub Issues](https://github.com/johnmathews/project-dashboard.nvim/issues)
- 📖 **Documentation**: [docs/](docs/) directory

---

Made with ❤️ for the Neovim community
