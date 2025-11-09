local M = {}

-- Function to create the dashboard buffer
function M.open()
  local start_time = vim.loop.hrtime()
  
  -- Check if we're in a git repo
  local git_stats = require('project-dashboard.git').get_git_stats()
  if not git_stats.current_branch then
    vim.notify('Not a git repository', vim.log.levels.WARN)
    return
  end

  -- Get all statistics
  local file_stats = require('project-dashboard.stats').get_file_stats()
  local config = require('project-dashboard').config
  
  -- Try to get GitHub info
  local github_info = nil
  if config.github.enabled and git_stats.owner and git_stats.repo_name then
    github_info = require('project-dashboard.git').get_github_info(
      git_stats.owner, 
      git_stats.repo_name, 
      config.github.timeout
    )
  end

  -- Create a new buffer
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, 'Project Dashboard')
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- Generate dashboard content
  local content = M.generate_dashboard_content(file_stats, git_stats, github_info)
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = vim.o.columns - 10,
    height = vim.o.lines - 10,
    col = 5,
    row = 5,
    border = 'rounded',
    style = 'minimal',
    title = ' Project Dashboard ',
    title_pos = 'center',
  })

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Set up keymaps to close dashboard
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })
  
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true,
  })

  -- Show timing if enabled
  if config.show_timing then
    local end_time = vim.loop.hrtime()
    local duration = (end_time - start_time) / 1000000 -- Convert to milliseconds
    print(string.format('Dashboard loaded in %.2f ms', duration))
  end
end

function M.generate_dashboard_content(file_stats, git_stats, github_info)
  local content = {}
  local config = require('project-dashboard').config
  
  -- Header
  table.insert(content, '')
  table.insert(content, '┌─────────────────────────────────────────────────────────────────┐')
  table.insert(content, '│                    📊 PROJECT DASHBOARD                      │')
  table.insert(content, '└─────────────────────────────────────────────────────────────────┘')
  table.insert(content, '')

  -- Project Info
  if git_stats.repo_name and git_stats.owner then
    table.insert(content, string.format('📁 Repository: %s/%s', git_stats.owner, git_stats.repo_name))
  else
    table.insert(content, '📁 Repository: ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t'))
  end
  table.insert(content, string.format('🌿 Branch: %s', git_stats.current_branch))
  table.insert(content, '')

  -- File Statistics
  table.insert(content, '📄 FILE STATISTICS')
  table.insert(content, string.format('   Total Files: %d', file_stats.total_files))
  table.insert(content, string.format('   Total Lines: %d', file_stats.total_lines))
  table.insert(content, '')

  -- Language breakdown
  if next(file_stats.languages) then
    table.insert(content, '💻 LANGUAGES')
    local sorted_languages = {}
    for lang, data in pairs(file_stats.languages) do
      table.insert(sorted_languages, { lang = lang, lines = data.lines, files = data.files })
    end
    
    -- Sort by lines of code
    table.sort(sorted_languages, function(a, b) return a.lines > b.lines end)
    
    for _, lang_data in ipairs(sorted_languages) do
      local percentage = math.floor((lang_data.lines / file_stats.total_lines) * 100)
      local bar = string.rep('█', math.floor(percentage / 5))
      table.insert(content, string.format('   %-15s %6d lines (%2d%%) %s', 
        lang_data.lang, lang_data.lines, percentage, bar))
    end
    table.insert(content, '')
  end

  -- Git Statistics
  table.insert(content, '🌿 GIT STATISTICS')
  table.insert(content, string.format('   Total Commits: %d', git_stats.total_commits))
  table.insert(content, string.format('   Branches: %d', #git_stats.branches))
  table.insert(content, string.format('   Remotes: %d', #git_stats.remotes))
  table.insert(content, '')

  -- Top Contributors
  if #git_stats.contributors > 0 then
    table.insert(content, '👥 TOP CONTRIBUTORS')
    local top_contributors = {}
    for i = 1, math.min(5, #git_stats.contributors) do
      table.insert(top_contributors, git_stats.contributors[i])
    end
    
    for _, contributor in ipairs(top_contributors) do
      table.insert(content, string.format('   %-20s %6d commits', contributor.name, contributor.commits))
    end
    table.insert(content, '')
  end

  -- GitHub Information
  if github_info then
    table.insert(content, '🐙 GITHUB INFORMATION')
    table.insert(content, string.format('   ⭐ Stars: %d', github_info.stars))
    table.insert(content, string.format('   🍴 Forks: %d', github_info.forks))
    table.insert(content, string.format('   🐛 Open Issues: %d', github_info.open_issues))
    if github_info.language then
      table.insert(content, string.format('   💻 Primary Language: %s', github_info.language))
    end
    if github_info.description then
      table.insert(content, string.format('   📝 Description: %s', github_info.description))
    end
    table.insert(content, '')
  end

  -- Footer
  table.insert(content, 'Press q or <Esc> to close')
  table.insert(content, '')

  return content
end

return M