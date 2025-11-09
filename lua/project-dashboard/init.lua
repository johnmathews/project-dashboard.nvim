local M = {}

-- Default configuration
local default_config = {
  -- Auto-open dashboard when entering a git repo
  auto_open = true,
  -- Show performance timing
  show_timing = true,
  -- More conservative auto-open behavior
  auto_open_conservative = true,
  -- GitHub data fetching
  github = {
    enabled = true,
    timeout = 5000, -- 5 seconds
  },
  -- Tile configuration
  tiles = {
    enabled = true,
    width = 40, -- tile width in characters
    height = 12, -- tile height in lines
    gap = 2, -- gap between tiles
    order = {
      'project_info',
      'file_stats', 
      'languages',
      'git_stats',
      'contributors',
      'github_info'
    },
    -- Tile properties configuration
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
        max_items = 5
      },
      git_stats = {
        title = '🌿 Git',
        fields = {'commits', 'branches', 'remotes'}
      },
      contributors = {
        title = '👥 Contributors',
        fields = {'top_contributors'},
        max_items = 3
      },
      github_info = {
        title = '🐙 GitHub',
        fields = {'stars', 'forks', 'issues'}
      }
    }
  }
}

-- Global config
M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', default_config, opts or {})

  -- Set up autocommands
  local group = vim.api.nvim_create_augroup('ProjectDashboard', { clear = true })

  if M.config.auto_open then
    vim.api.nvim_create_autocmd('VimEnter', {
      group = group,
      callback = function()
        -- Conservative mode: don't open if there are any signs of session/file loading
        if M.config.auto_open_conservative then
          -- Don't open if files were specified on command line
          if vim.fn.argc() > 0 then
            return
          end
          
          -- Check if a session is being loaded via command line args
          for _, arg in ipairs(vim.v.argv) do
            if arg:match('%-S') or arg:match('%-session') or arg:match('%.vim$') then
              return
            end
          end
          
          -- Check if any buffers already have files loaded
          local has_file_buffers = false
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_option(buf, 'buftype') == '' then
              local name = vim.api.nvim_buf_get_name(buf)
              if name ~= '' and not name:match('project%-dashboard') then
                has_file_buffers = true
                break
              end
            end
          end
          
          if has_file_buffers then
            return
          end
        else
          -- Original behavior: only check command line args
          if vim.fn.argc() > 0 then
            return
          end
        end
        
        -- Only open if we're in a git repo
        if M.is_git_repo() then
          -- Small delay to ensure everything is loaded
          vim.defer_fn(function()
            require('project-dashboard.dashboard').open()
          end, 100)
        end
      end,
    })
  end

  -- Create user command
  vim.api.nvim_create_user_command('ProjectDashboard', function()
    require('project-dashboard.dashboard').open()
  end, {})
end

function M.is_git_repo()
  return vim.fn.isdirectory('.git') == 1 or vim.fn.system('git rev-parse --git-dir 2>/dev/null'):match('%S')
end

function M.get_git_info()
  local git_info = {
    is_repo = false,
    current_branch = nil,
    has_github_remote = false,
    github_owner = nil,
    github_repo = nil
  }

  -- Check if we're in a git repo
  if not M.is_git_repo() then
    return git_info
  end

  git_info.is_repo = true

  -- Get current branch
  local current_branch_cmd = 'git rev-parse --abbrev-ref HEAD 2>/dev/null'
  local current_branch = vim.fn.system(current_branch_cmd):gsub('%s+', '')
  if vim.v.shell_error == 0 then
    git_info.current_branch = current_branch
  end

  -- Check for GitHub remotes
  local remotes_cmd = 'git remote -v 2>/dev/null'
  local remotes_output = vim.fn.system(remotes_cmd)
  if vim.v.shell_error == 0 then
    for line in remotes_output:gmatch('[^\r\n]+') do
      local url = line:match('%s+(%S+)')
      if url and url:match('github%.com') then
        git_info.has_github_remote = true
        -- Handle both SSH and HTTPS URLs:
        -- SSH: git@github.com:owner/repo.git
        -- HTTPS: https://github.com/owner/repo.git
        local owner, repo = url:match('github%.com[:/](%w+)/([^/]+)%.git')
        if owner and repo then
          git_info.github_owner = owner
          git_info.github_repo = repo:gsub('%.git$', '')
        end
        break
      end
    end
  end

  return git_info
end

return M