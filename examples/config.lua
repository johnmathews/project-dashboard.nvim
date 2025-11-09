-- Example configuration for project-dashboard.nvim
-- This shows all available configuration options with their defaults

require('project-dashboard').setup({
  -- Auto-open dashboard when entering a git repository
  auto_open = true,
  
  -- Show performance timing in the command line
  show_timing = true,
  
  -- Conservative auto-open behavior (recommended)
  -- Won't open if files are specified on command line or session is being loaded
  auto_open_conservative = true,
  
  -- Layout configuration
  layout = {
    margin_x = 8,  -- horizontal margin from screen edges (increase for more padding)
    margin_y = 1,  -- vertical margin from top/bottom (increase for more vertical padding)
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
    width = 45,   -- minimum tile width (tiles expand to fill available space)
    height = 12,  -- tile height in lines
    
    -- Spacing
    gap_x = 3,  -- horizontal gap between tiles
    gap_y = 1,  -- vertical gap between tile rows
    
    -- Tile display order (top to bottom, left to right)
    order = {
      'project_info',
      'file_stats', 
      'languages',
      'git_stats',
      'contributors',
      'github_info'
    },
    
    -- Individual tile configuration
    properties = {
      project_info = {
        title = '📁 Project',
        fields = {'name', 'branch', 'remote'}
      },
      file_stats = {
        title = '📄 Files',
        fields = {'total_files', 'total_lines'}
      },
      languages = {
        title = '💻 Languages',
        fields = {'breakdown'},
        max_items = 5  -- show top 5 languages
      },
      git_stats = {
        title = '🌿 Git',
        fields = {'commits', 'branches', 'remotes'}
      },
      contributors = {
        title = '👥 Contributors',
        fields = {'top_contributors'},
        max_items = 3  -- show top 3 contributors
      },
      github_info = {
        title = '🐙 GitHub',
        fields = {'stars', 'forks', 'issues'}
      }
    }
  }
})

-- Usage examples:
--
-- Minimal configuration:
--   require('project-dashboard').setup({})
--
-- More screen padding:
--   require('project-dashboard').setup({
--     layout = { margin_x = 15, margin_y = 3 }
--   })
--
-- Tighter tile spacing:
--   require('project-dashboard').setup({
--     tiles = { gap_x = 2, gap_y = 0 }
--   })
--
-- Disable auto-open:
--   require('project-dashboard').setup({
--     auto_open = false
--   })
--   Then manually open with :ProjectDashboard
