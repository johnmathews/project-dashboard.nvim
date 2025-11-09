local M = {}

-- Border character sets
local border_chars = {
  rounded = {
    top_left = '╭',
    top_right = '╮',
    bottom_left = '╰',
    bottom_right = '╯',
    horizontal = '─',
    vertical = '│'
  },
  square = {
    top_left = '┌',
    top_right = '┐',
    bottom_left = '└',
    bottom_right = '┘',
    horizontal = '─',
    vertical = '│'
  }
}


-- Tile rendering functions
local tile_renderers = {}

function tile_renderers.project_info(data, config)
  local lines = {}
  local git_info = data.git_stats or {}
  
  table.insert(lines, config.title)
  table.insert(lines, '')
  
  -- Project name
  local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':t')
  if git_info.github_owner and git_info.github_repo then
    project_name = string.format('%s/%s', git_info.github_owner, git_info.github_repo)
  end
  table.insert(lines, string.format('Name: %s', project_name))
  
  -- Branch info
  if git_info.is_repo and git_info.current_branch then
    table.insert(lines, string.format('Branch: %s', git_info.current_branch))
  else
    table.insert(lines, 'Branch: Not a git repository')
  end
  
  -- Remote info
  if git_info.has_github_remote then
    table.insert(lines, 'Remote: GitHub ✓')
  elseif git_info.is_repo then
    table.insert(lines, 'Remote: Non-GitHub')
  else
    table.insert(lines, 'Remote: None')
  end
  
  return lines
end

function tile_renderers.file_stats(data, config)
  local lines = {}
  local file_stats = data.file_stats or {}
  
  table.insert(lines, config.title)
  table.insert(lines, '')
  
  if file_stats.loading then
    table.insert(lines, string.format('Loading... %d%%', file_stats.progress or 0))
    local bar_width = 20
    local filled = math.floor(((file_stats.progress or 0) / 100) * bar_width)
    local bar = '█' .. string.rep('█', filled) .. string.rep('░', bar_width - filled)
    table.insert(lines, string.format('[%s]', bar))
  else
    table.insert(lines, string.format('Files: %d', file_stats.total_files or 0))
    table.insert(lines, string.format('Lines: %d', file_stats.total_lines or 0))
  end
  
  return lines
end

function tile_renderers.languages(data, config)
  local lines = {}
  local file_stats = data.file_stats or {}
  
  table.insert(lines, config.title)
  table.insert(lines, '')
  
  if file_stats.loading then
    table.insert(lines, 'Loading...')
  elseif not file_stats.languages or not next(file_stats.languages) then
    table.insert(lines, 'No source files')
  else
    local sorted_languages = {}
    for lang, lang_data in pairs(file_stats.languages) do
      table.insert(sorted_languages, { lang = lang, lines = lang_data.lines })
    end
    
    table.sort(sorted_languages, function(a, b) return a.lines > b.lines end)
    
    local max_items = math.min(config.max_items or 5, #sorted_languages)
    for i = 1, max_items do
      local lang_data = sorted_languages[i]
      local percentage = math.floor((lang_data.lines / file_stats.total_lines) * 100)
      local bar = string.rep('█', math.floor(percentage / 10))
      table.insert(lines, string.format('%-12s %3d%% %s', 
        lang_data.lang, percentage, bar))
    end
  end
  
  return lines
end

function tile_renderers.git_stats(data, config)
  local lines = {}
  local git_stats = data.git_stats or {}
  
  table.insert(lines, config.title)
  table.insert(lines, '')
  
  if not git_stats.is_repo then
    table.insert(lines, 'Not a git repository')
  elseif git_stats.loading then
    table.insert(lines, 'Loading...')
  else
    table.insert(lines, string.format('Commits: %d', git_stats.total_commits or 0))
    table.insert(lines, string.format('Branches: %d', #git_stats.branches))
    table.insert(lines, string.format('Remotes: %d', #git_stats.remotes))
  end
  
  return lines
end

function tile_renderers.contributors(data, config)
  local lines = {}
  local git_stats = data.git_stats or {}
  
  table.insert(lines, config.title)
  table.insert(lines, '')
  
  if not git_stats.is_repo then
    table.insert(lines, 'Not a git repository')
  elseif git_stats.loading then
    table.insert(lines, 'Loading...')
  elseif not git_stats.contributors or #git_stats.contributors == 0 then
    table.insert(lines, 'No contributors')
  else
    local max_items = math.min(config.max_items or 3, #git_stats.contributors)
    for i = 1, max_items do
      local contributor = git_stats.contributors[i]
      local name = contributor.name
      if #name > 15 then
        name = name:sub(1, 12) .. '...'
      end
      table.insert(lines, string.format('%-15s %3d', name, contributor.commits))
    end
  end
  
  return lines
end

function tile_renderers.github_info(data, config)
  local lines = {}
  local github_info = data.github_info
  local git_stats = data.git_stats or {}
  
  table.insert(lines, config.title)
  table.insert(lines, '')
  
  if not git_stats.has_github_remote then
    table.insert(lines, 'No GitHub remote')
  elseif github_info then
    if github_info.error then
      table.insert(lines, 'Failed to fetch')
    else
      table.insert(lines, string.format('⭐ %d', github_info.stars or 0))
      table.insert(lines, string.format('🍴 %d', github_info.forks or 0))
      table.insert(lines, string.format('🐛 %d', github_info.open_issues or 0))
    end
  elseif git_stats.is_repo then
    table.insert(lines, 'Loading...')
  else
    table.insert(lines, 'Not available')
  end
  
  return lines
end

-- Main tile layout function
function M.create_tiled_layout(data, config)
  local tiles_config = config.tiles
  local tile_width = tiles_config.width
  local tile_height = tiles_config.height
  local gap_x = tiles_config.gap_x or tiles_config.gap or 3 -- horizontal gap between tiles
  local gap_y = tiles_config.gap_y or 1 -- vertical gap between rows
  
  -- Calculate layout
  local margin_x = config.layout and config.layout.margin_x or 8
  local window_width = vim.o.columns - (margin_x * 2)
  
  -- Account for edge gaps (left and right)
  local available_width = window_width - (gap_x * 2)
  local tiles_per_row = math.floor((available_width + gap_x) / (tile_width + gap_x))
  
  -- Ensure at least 1 tile per row
  if tiles_per_row < 1 then
    tiles_per_row = 1
  end
  
  -- Calculate dynamic tile width to fill available space
  -- Total gaps: (tiles_per_row - 1) between tiles + 2 edge gaps
  local total_gap_width = (tiles_per_row - 1) * gap_x
  local calculated_tile_width = math.floor((available_width - total_gap_width) / tiles_per_row)
  
  -- Use calculated width if it's reasonable, otherwise use config width
  if calculated_tile_width > tile_width then
    tile_width = calculated_tile_width
  end
  
  -- Generate tiles
  local tiles = {}
  for _, tile_id in ipairs(tiles_config.order) do
    local tile_config = tiles_config.properties[tile_id]
    if tile_config then
      local renderer = tile_renderers[tile_id]
      if renderer then
        local content = renderer(data, tile_config)
        table.insert(tiles, {
          id = tile_id,
          content = content,
          config = tile_config
        })
      end
    end
  end
  
  -- Layout tiles in grid
  local layout = {}
  local row = 0
  local col = 0
  
  for _, tile in ipairs(tiles) do
    table.insert(layout, {
      row = row,
      col = col,
      width = tile_width,
      height = tile_height,
      content = tile.content
    })
    
    col = col + 1
    if col >= tiles_per_row then
      col = 0
      row = row + 1
    end
  end
  
  return layout
end

-- Render tiled layout to buffer lines
function M.render_tiled_content(layout, config)
  local lines = {}
  local max_row = 0
  
  -- Extract configuration
  local tiles_config = config.tiles
  local tile_height = tiles_config.height
  local gap_x = tiles_config.gap_x or tiles_config.gap or 3
  local gap_y = tiles_config.gap_y or 1
  
  -- Get border style
  local border_style = tiles_config.border_style or 'rounded'
  local borders = border_chars[border_style] or border_chars.rounded
  
  -- Find maximum row
  for _, tile in ipairs(layout) do
    max_row = math.max(max_row, tile.row)
  end
  
  -- Render each row
  for row = 0, max_row do
    -- Get tiles in this row
    local row_tiles = {}
    for _, tile in ipairs(layout) do
      if tile.row == row then
        table.insert(row_tiles, tile)
      end
    end
    
    -- Sort tiles by column
    table.sort(row_tiles, function(a, b) return a.col < b.col end)
    
    -- Render top border
    local top_border = string.rep(' ', gap_x)  -- left edge margin
    for i, tile in ipairs(row_tiles) do
      if i > 1 then
        top_border = top_border .. string.rep(' ', gap_x)
      end
      top_border = top_border .. borders.top_left .. string.rep(borders.horizontal, tile.width - 2) .. borders.top_right
    end
    table.insert(lines, top_border)
    
    -- Render content lines with side borders
    for line = 1, tile_height - 2 do
      local row_line = string.rep(' ', gap_x)  -- left edge margin
      
      for i, tile in ipairs(row_tiles) do
        if i > 1 then
          row_line = row_line .. string.rep(' ', gap_x)
        end
        
        -- Get tile content for this line
        local tile_line = tile.content[line] or ''
        -- Calculate available content width (tile.width - 4 for borders and padding)
        local content_width = tile.width - 4
        
        -- Use display width to account for wide characters (emojis, etc.)
        local display_width = vim.fn.strdisplaywidth(tile_line)
        
        if display_width > content_width then
          -- Truncate if too long - need to be careful with multi-byte chars
          while vim.fn.strdisplaywidth(tile_line) > content_width and #tile_line > 0 do
            tile_line = tile_line:sub(1, -2)
          end
        else
          -- Pad with spaces if too short
          tile_line = tile_line .. string.rep(' ', content_width - display_width)
        end
        
        row_line = row_line .. borders.vertical .. ' ' .. tile_line .. ' ' .. borders.vertical
      end
      
      table.insert(lines, row_line)
    end
    
    -- Render bottom border
    local bottom_border = string.rep(' ', gap_x)  -- left edge margin
    for i, tile in ipairs(row_tiles) do
      if i > 1 then
        bottom_border = bottom_border .. string.rep(' ', gap_x)
      end
      bottom_border = bottom_border .. borders.bottom_left .. string.rep(borders.horizontal, tile.width - 2) .. borders.bottom_right
    end
    table.insert(lines, bottom_border)
    
    -- Add gap between rows (except last)
    if row < max_row then
      for _ = 1, gap_y do
        table.insert(lines, '')
      end
    end
  end
  
  return lines
end

return M
