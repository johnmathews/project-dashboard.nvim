local M = {}

-- Default configuration
local default_config = {
  -- Auto-open dashboard when entering a git repo
  auto_open = true,
  -- Show performance timing
  show_timing = true,
  -- GitHub data fetching
  github = {
    enabled = true,
    timeout = 5000, -- 5 seconds
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
        -- Only open if no file specified and we're in a git repo
        if vim.fn.argc() == 0 and M.is_git_repo() then
          require('project-dashboard.dashboard').open()
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

return M