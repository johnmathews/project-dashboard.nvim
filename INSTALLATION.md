# 📦 Installation Guide for Lazy.nvim

## 🚀 Quick Setup

### Step 1: Add to Your Lazy.nvim Config

Add this to your lazy.nvim plugin setup (usually in `lua/plugins/` or your main config):

```lua
-- Method 1: Direct path (recommended for development)
{
  dir = '/Users/john/projects/neovim-dashboard',
  name = 'project-dashboard.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
  },
  config = function()
    require('project-dashboard').setup({
      auto_open = true,        -- Auto-open in git repos
      show_timing = true,      -- Show load performance
      github = {
        enabled = true,
        timeout = 5000,        -- GitHub API timeout
      }
    })
  end,
  event = 'VimEnter',        -- Load on startup
},
```

### Step 2: Restart Neovim

```bash
# Restart neovim to load the new plugin
nvim
```

### Step 3: Test It

```vim
:ProjectDashboard
```

Or navigate to any git repository without specifying a file - it should auto-open!

## 🔧 Configuration Options

```lua
require('project-dashboard').setup({
  auto_open = true,        -- Auto-open when entering git repos
  show_timing = true,      -- Show load performance in ms
  github = {
    enabled = true,        -- Fetch GitHub data (stars, forks, etc.)
    timeout = 5000,       -- GitHub API timeout in ms
  }
})
```

## 📁 Path Options

### Option 1: Absolute Path (Simple)
```lua
dir = '/Users/john/projects/neovim-dashboard'
```

### Option 2: Home Expansion (Portable)
```lua
dir = vim.fn.expand('~/projects/neovim-dashboard')
```

### Option 3: File URL (Git-like)
```lua
'file:///Users/john/projects/neovim-dashboard'
```

## 🎯 Usage

### Automatic
- Open neovim in any git repository without a file
- Dashboard appears automatically

### Manual
```vim
:ProjectDashboard
```

### Close Dashboard
- Press `q` or `<Esc>`

## 🚀 What You'll See

```
┌─────────────────────────────────────────────────────────────────┐
│                    📊 PROJECT DASHBOARD                      │
└─────────────────────────────────────────────────────────────────┘

📁 Repository: your-repo/your-project
🌿 Branch: main

📄 FILE STATISTICS
   Total Files: 42
   Total Lines: 1,247

💻 LANGUAGES
   Lua           1,100 lines (88%) ████████████████████████████████
   Markdown        147 lines (12%) ████████

🌿 GIT STATISTICS
   Total Commits: 23
   Branches: 3
   Remotes: 2

👥 TOP CONTRIBUTORS
   John Doe            15 commits
   Jane Smith           8 commits

🐙 GITHUB INFORMATION
   ⭐ Stars: 42
   🍴 Forks: 8
   🐛 Open Issues: 3

Press q or <Esc> to close
```

## 🔍 Troubleshooting

### Plugin Not Loading
1. Check the path is correct
2. Ensure dependencies are installed
3. Run `:Lazy` to see plugin status

### Dashboard Not Auto-Opening
1. Make sure `auto_open = true` in config
2. Verify you're in a git repository (`git status`)
3. Try manual command `:ProjectDashboard`

### GitHub Data Missing
1. Check `github.enabled = true`
2. Verify remote is a GitHub URL
3. Check internet connection

### Performance Issues
- Large repos may take longer to scan
- Progress bar shows loading status
- UI remains responsive during loading

## 🎉 Done!

Your project-dashboard.nvim is now integrated with lazy.nvim and ready to use! The dashboard will automatically show project insights whenever you enter a git repository.