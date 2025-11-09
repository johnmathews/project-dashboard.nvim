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
  local margin_x = config.layout and config.layout.margin_x or 8
  local margin_y = config.layout and config.layout.margin_y or 1
  
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = vim.o.columns - (margin_x * 2),
    height = vim.o.lines - (margin_y * 2),
    col = margin_x,
    row = margin_y,
    border = 'rounded',
    style = 'minimal',
    title = ' Project Dashboard ',
    title_pos = 'center',
  })

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Set up syntax highlighting
  M.setup_highlights(buf)

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
  
  -- Resize window to fit content (don't show excessive blank space)
  local margin_x = config.layout and config.layout.margin_x or 8
  local margin_y = config.layout and config.layout.margin_y or 1
  local content_height = #content
  local max_height = vim.o.lines - (margin_y * 2)
  
  -- Use exact content height (the border adds visual padding)
  local window_height = math.min(content_height, max_height)
  
  vim.api.nvim_win_set_config(win, {
    relative = 'editor',
    width = vim.o.columns - (margin_x * 2),
    height = window_height,
    col = margin_x,
    row = margin_y,
  })

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
  local title_display_width = vim.fn.strdisplaywidth(title)
  local padding_needed = box_width - title_display_width
  local left_padding = math.floor(padding_needed / 2)
  local right_padding = padding_needed - left_padding
  local centered_title = '│' .. string.rep(' ', left_padding) .. title .. string.rep(' ', right_padding) .. '│'
  
  -- Center the entire title box in the window
  local margin_x = config.layout and config.layout.margin_x or 8
  local window_width = vim.o.columns - (margin_x * 2)
  local box_left_margin = math.floor((window_width - (box_width + 2)) / 2)
  local margin = string.rep(' ', box_left_margin)
  
  table.insert(content, '')
  table.insert(content, margin .. '┌' .. string.rep('─', box_width) .. '┐')
  table.insert(content, margin .. centered_title)
  table.insert(content, margin .. '└' .. string.rep('─', box_width) .. '┘')
  table.insert(content, '')

  -- Check if tiles are enabled
  if config.tiles and config.tiles.enabled then
    -- Use tiled layout
    local tiles = require('project-dashboard.tiles')
    local layout = tiles.create_tiled_layout(dashboard_data, config)
    local tiled_content = tiles.render_tiled_content(layout, config)
    
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

-- Setup syntax highlighting for dashboard
function M.setup_highlights(buf)
  -- Define custom highlight groups
  vim.api.nvim_set_hl(0, 'DashboardTitle', { fg = '#61afef', bold = true }) -- Blue
  vim.api.nvim_set_hl(0, 'DashboardHeader', { fg = '#565f89' }) -- Dark gray
  vim.api.nvim_set_hl(0, 'DashboardFooter', { fg = '#565f89' }) -- Dark gray
  vim.api.nvim_set_hl(0, 'DashboardTileTitle', { fg = '#e0af68', bold = true }) -- Yellow
  vim.api.nvim_set_hl(0, 'DashboardTileSeparator', { fg = '#414868' }) -- Medium gray
  vim.api.nvim_set_hl(0, 'DashboardKey', { fg = '#9ece6a' }) -- Green
  vim.api.nvim_set_hl(0, 'DashboardValue', { fg = '#c0caf5' }) -- Light blue
  vim.api.nvim_set_hl(0, 'DashboardLoading', { fg = '#f7768e', bold = true }) -- Red
  vim.api.nvim_set_hl(0, 'DashboardSuccess', { fg = '#9ece6a' }) -- Green
  vim.api.nvim_set_hl(0, 'DashboardWarning', { fg = '#e0af68' }) -- Yellow
  vim.api.nvim_set_hl(0, 'DashboardError', { fg = '#f7768e' }) -- Red
  vim.api.nvim_set_hl(0, 'DashboardLanguage', { fg = '#bb9af7' }) -- Purple
  vim.api.nvim_set_hl(0, 'DashboardProgress', { fg = '#7aa2f7' }) -- Blue
  vim.api.nvim_set_hl(0, 'DashboardGitHub', { fg = '#7aa2f7' }) -- Blue

  -- Apply highlights using buffer API (more reliable)
  vim.defer_fn(function()
    if not vim.api.nvim_buf_is_valid(buf) then return end
    
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for i, line in ipairs(lines) do
      -- Header and footer
      if line:match('📊 PROJECT DASHBOARD') then
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardTitle', i-1, 0, -1)
      elseif line:match('^[│┌└─]') then
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardHeader', i-1, 0, -1)
      elseif line:match('^Press') then
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardFooter', i-1, 0, -1)
      
      -- Tile titles and separators
      elseif line:match('^[│├┤] [^│]*[│├┤]$') and not line:match('─') then
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardTileTitle', i-1, 0, -1)
      elseif line:match('^[│├┤] [─ ]*[│├┤]$') then
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardTileSeparator', i-1, 0, -1)
      
      -- Key-value pairs
      elseif line:match('^[│├┤] [^:]*:') then
        local key_end = line:find(':')
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardKey', i-1, 0, key_end)
        vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardValue', i-1, key_end, -1)
      
      -- Special values
      elseif line:match('Loading') then
        local start = line:find('Loading')
        if start then
          vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardLoading', i-1, start-1, -1)
        end
      elseif line:match('✓') then
        local start = line:find('✓')
        if start then
          vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardSuccess', i-1, start-1, start)
        end
      elseif line:match('⭐') or line:match('🍴') or line:match('🐙') or line:match('🐛') then
        for emoji in line:gmatch('[⭐🍴🐙🐛]') do
          local start = line:find(emoji)
          if start then
            vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardGitHub', i-1, start-1, start)
          end
        end
      
      -- Languages
      elseif line:match('%a+') then
        for lang in line:gmatch('%a+') do
          if lang:match('Lua') or lang:match('Python') or lang:match('JavaScript') or 
             lang:match('TypeScript') or lang:match('Markdown') or lang:match('Shell') or
             lang:match('JSON') or lang:match('Go') or lang:match('Rust') or 
             lang:match('Java') or lang:match('Ruby') or lang:match('PHP') or 
             lang:match('CSS') or lang:match('HTML') then
            local start = line:find(lang)
            if start then
              vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardLanguage', i-1, start-1, start+#lang-1)
            end
          end
        end
      
      -- Progress bars
      elseif line:match('[█▓▒░]') then
        for bar in line:gmatch('[█▓▒░]+') do
          local start = line:find(bar)
          if start then
            vim.api.nvim_buf_add_highlight(buf, -1, 'DashboardProgress', i-1, start-1, start+#bar-1)
          end
        end
      end
    end
  end, 50)
end

return M