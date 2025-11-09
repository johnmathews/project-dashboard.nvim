local M = {}

-- Function to create dashboard buffer with async loading and tiled layout
function M.open()
  local start_time = vim.loop.hrtime()
  
  local config = require('project-dashboard').config
  
  -- Create a new buffer immediately
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer name
  vim.api.nvim_buf_set_name(buf, 'Project Dashboard')
  
  -- Set buffer options with error handling
  local success, err = pcall(function()
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  end)
  
  if not success then
    vim.notify('Failed to setup dashboard buffer: ' .. tostring(err), vim.log.levels.ERROR)
    return
  end

  -- Create window immediately
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

  -- Store data for updates
  local dashboard_data = {
    file_stats = { loading = true, progress = 0 },
    git_stats = { loading = true },
    github_info = nil,
    buf = buf,
    win = win,
    start_time = start_time
  }

  -- Show initial loading state
  M.update_dashboard_content(dashboard_data, config)

  -- Start async data loading
  M.load_data_async(dashboard_data, config)
end

-- Async data loading function
function M.load_data_async(dashboard_data, config)
  -- Load file stats async
  require('project-dashboard.stats').get_file_stats_async(function(status, data)
    if status == 'progress' then
      dashboard_data.file_stats = data
      M.update_dashboard_content(dashboard_data, config)
    elseif status == 'complete' then
      dashboard_data.file_stats = data
      M.update_dashboard_content(dashboard_data, config)
    end
  end)

  -- Load git stats async
  require('project-dashboard.git').get_git_stats_async(function(status, data)
    if status == 'complete' then
      dashboard_data.git_stats = data
      
      -- Start GitHub API call if we have owner/repo
      if config.github.enabled and data.has_github_remote and data.github_owner and data.github_repo then
        require('project-dashboard.git').get_github_info_async(
          data.github_owner, 
          data.github_repo, 
          config.github.timeout,
          function(status, github_data)
            if status == 'complete' then
              dashboard_data.github_info = github_data
              M.update_dashboard_content(dashboard_data, config)
            elseif status == 'error' then
              dashboard_data.github_info = { error = true }
              M.update_dashboard_content(dashboard_data, config)
            end
          end
        )
      end
      
      M.update_dashboard_content(dashboard_data, config)
    end
  end)
end

-- Update dashboard content progressively
function M.update_dashboard_content(dashboard_data, config)
  local buf = dashboard_data.buf
  local win = dashboard_data.win
  
  -- Check if window and buffer are still valid
  if not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  
  -- Generate content with current data
  local content = M.generate_dashboard_content(dashboard_data, config)
  
  -- Update buffer content with error handling
  local success, err = pcall(function()
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  end)
  
  if not success then
    -- Buffer was likely replaced by session loading, stop updating
    return
  end

  -- Show timing if everything is loaded
  if config.show_timing and 
     not dashboard_data.file_stats.loading and 
     not dashboard_data.git_stats.loading and
     (dashboard_data.github_info or not dashboard_data.git_stats.has_github_remote) then
    local end_time = vim.loop.hrtime()
    local duration = (end_time - dashboard_data.start_time) / 1000000 -- Convert to milliseconds
    print(string.format('Dashboard loaded in %.2f ms', duration))
  end
end

function M.generate_dashboard_content(dashboard_data, config)
  local content = {}
  
  -- Header (centered)
  local title = '📊 PROJECT DASHBOARD'
  local box_width = 65
  local title_padding = string.rep(' ', math.floor((box_width - #title) / 2))
  local centered_title = '│' .. title_padding .. title .. title_padding .. '│'
  
  table.insert(content, '')
  table.insert(content, '┌' .. string.rep('─', box_width) .. '┐')
  table.insert(content, centered_title)
  table.insert(content, '└' .. string.rep('─', box_width) .. '┘')
  table.insert(content, '')

  -- Check if tiles are enabled
  if config.tiles and config.tiles.enabled then
    -- Use tiled layout
    local tiles = require('project-dashboard.tiles')
    local layout = tiles.create_tiled_layout(dashboard_data, config)
    local tiled_content = tiles.render_tiled_content(
      layout, 
      config.tiles.width, 
      config.tiles.height, 
      config.tiles.gap
    )
    
    -- Add tiled content to main content
    for _, line in ipairs(tiled_content) do
      table.insert(content, line)
    end
  else
    -- Fallback to original layout
    local fallback_content = M.generate_fallback_content(dashboard_data)
    for _, line in ipairs(fallback_content) do
      table.insert(content, line)
    end
  end

  -- Footer
  table.insert(content, '')
  table.insert(content, 'Press q or <Esc> to close')
  table.insert(content, '')

  return content
end

function M.generate_fallback_content(dashboard_data)
  local content = {}
  local file_stats = dashboard_data.file_stats
  local git_stats = dashboard_data.git_stats
  local github_info = dashboard_data.github_info
  
  -- Project Info
  if git_stats.is_repo then
    if git_stats.github_owner and git_stats.github_repo then
      table.insert(content, string.format('📁 Repository: %s/%s', git_stats.github_owner, git_stats.github_repo))
    else
      table.insert(content, '📁 Repository: ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t'))
    end
    
    if git_stats.current_branch then
      table.insert(content, string.format('🌿 Branch: %s', git_stats.current_branch))
    else
      table.insert(content, '🌿 Branch: N/A')
    end
  else
    table.insert(content, '📁 Repository: ' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t'))
    table.insert(content, '🌿 Branch: Not a git repository')
  end
  table.insert(content, '')

  -- File Statistics
  table.insert(content, '📄 FILE STATISTICS')
  if file_stats.loading then
    table.insert(content, string.format('   Loading files... %d%%', file_stats.progress or 0))
    local bar_width = 30
    local filled = math.floor((file_stats.progress or 0) / 100 * bar_width)
    local bar = '█' .. string.rep('█', filled) .. string.rep('░', bar_width - filled)
    table.insert(content, string.format('   [%s]', bar))
  else
    table.insert(content, string.format('   Total Files: %d', file_stats.total_files))
    table.insert(content, string.format('   Total Lines: %d', file_stats.total_lines))
  end
  table.insert(content, '')

  -- Language breakdown
  if not file_stats.loading and next(file_stats.languages) then
    table.insert(content, '💻 LANGUAGES')
    local sorted_languages = {}
    for lang, data in pairs(file_stats.languages) do
      table.insert(sorted_languages, { lang = lang, lines = data.lines, files = data.files })
    end
    
    table.sort(sorted_languages, function(a, b) return a.lines > b.lines end)
    
    for _, lang_data in ipairs(sorted_languages) do
      local percentage = math.floor((lang_data.lines / file_stats.total_lines) * 100)
      local bar = string.rep('█', math.floor(percentage / 5))
      table.insert(content, string.format('   %-15s %6d lines (%2d%%) %s', 
        lang_data.lang, lang_data.lines, percentage, bar))
    end
    table.insert(content, '')
  elseif not file_stats.loading then
    table.insert(content, '💻 LANGUAGES')
    table.insert(content, '   No source files found')
    table.insert(content, '')
  end

  -- Git Statistics
  table.insert(content, '🌿 GIT STATISTICS')
  if not git_stats.is_repo then
    table.insert(content, '   Not a git repository')
  elseif git_stats.loading then
    table.insert(content, '   Loading git statistics...')
  else
    table.insert(content, string.format('   Total Commits: %d', git_stats.total_commits))
    table.insert(content, string.format('   Branches: %d', #git_stats.branches))
    table.insert(content, string.format('   Remotes: %d', #git_stats.remotes))
  end
  table.insert(content, '')

  -- Top Contributors
  if not git_stats.loading and git_stats.is_repo and #git_stats.contributors > 0 then
    table.insert(content, '👥 TOP CONTRIBUTORS')
    local top_contributors = {}
    for i = 1, math.min(5, #git_stats.contributors) do
      table.insert(top_contributors, git_stats.contributors[i])
    end
    
    for _, contributor in ipairs(top_contributors) do
      table.insert(content, string.format('   %-20s %6d commits', contributor.name, contributor.commits))
    end
    table.insert(content, '')
  elseif not git_stats.loading and git_stats.is_repo then
    table.insert(content, '👥 TOP CONTRIBUTORS')
    table.insert(content, '   No contributors found')
    table.insert(content, '')
  end

  -- GitHub Information
  if github_info then
    if github_info.error then
      table.insert(content, '🐙 GITHUB INFORMATION')
      table.insert(content, '   Unable to fetch GitHub data')
      table.insert(content, '')
    else
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
  elseif not git_stats.loading and git_stats.is_repo then
    if git_stats.has_github_remote then
      table.insert(content, '🐙 GITHUB INFORMATION')
      table.insert(content, '   Loading GitHub data...')
      table.insert(content, '')
    else
      table.insert(content, '🐙 GITHUB INFORMATION')
      table.insert(content, '   No GitHub remote found')
      table.insert(content, '')
    end
  end

  return content
end

return M