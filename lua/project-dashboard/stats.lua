local M = {}

-- Async function to get file statistics
function M.get_file_stats_async(callback)
  local stats = {
    total_files = 0,
    total_lines = 0,
    languages = {},
    file_extensions = {},
    loading = true
  }

  -- Use plenary for async file scanning
  local scan = require('plenary.scandir')

  -- Run file scanning in a coroutine to avoid blocking
  vim.defer_fn(function()
    local files = scan.scan_dir('.', {
      hidden = false,
      respect_gitignore = true,
      add_dirs = false,
    })

    -- Process files in chunks to avoid blocking
    local chunk_size = 50
    local processed = 0
    
    local function process_chunk()
      local start_idx = processed + 1
      local end_idx = math.min(processed + chunk_size, #files)
      
      for i = start_idx, end_idx do
        local file = files[i]
        -- Skip .git directory and other common ignores
        if not file:match('%.git/') and not file:match('node_modules/') and not file:match('target/') and not file:match('%.vscode/') and not file:match('build/') and not file:match('dist/') then
          stats.total_files = stats.total_files + 1
          
          -- Get file extension
          local ext = file:match('%.([^%.]+)$') or 'no_extension'
          stats.file_extensions[ext] = (stats.file_extensions[ext] or 0) + 1
          
          -- Count lines (simplified - just read file and count newlines)
          local lines = 0
          local f = io.open(file, 'r')
          if f then
            for _ in f:lines() do
              lines = lines + 1
            end
            f:close()
            stats.total_lines = stats.total_lines + lines
            
            -- Map extension to language
            local language = M.extension_to_language(ext)
            if language then
              stats.languages[language] = {
                files = (stats.languages[language] and stats.languages[language].files or 0) + 1,
                lines = (stats.languages[language] and stats.languages[language].lines or 0) + lines
              }
            end
          end
        end
      end
      
      processed = end_idx
      
      -- Update progress and continue or finish
      if processed < #files then
        -- Send progress update
        stats.progress = math.floor((processed / #files) * 100)
        callback('progress', stats)
        -- Schedule next chunk
        vim.defer_fn(process_chunk, 1)
      else
        -- Finished
        stats.loading = false
        stats.progress = 100
        callback('complete', stats)
      end
    end
    
    -- Start processing
    process_chunk()
  end, 10) -- Small delay to allow UI to render first
end

-- Synchronous version for fallback
function M.get_file_stats()
  local stats = {
    total_files = 0,
    total_lines = 0,
    languages = {},
    file_extensions = {}
  }

  -- Use plenary for file scanning
  local scan = require('plenary.scandir')

  -- Get all files in current directory (recursively)
  local files = scan.scan_dir('.', {
    hidden = false,
    respect_gitignore = true,
    add_dirs = false,
  })

  for _, file in ipairs(files) do
    -- Skip .git directory and other common ignores
    if not file:match('%.git/') and not file:match('node_modules/') and not file:match('target/') and not file:match('%.vscode/') and not file:match('build/') and not file:match('dist/') then
      stats.total_files = stats.total_files + 1
      
      -- Get file extension
      local ext = file:match('%.([^%.]+)$') or 'no_extension'
      stats.file_extensions[ext] = (stats.file_extensions[ext] or 0) + 1
      
      -- Count lines (simplified - just read file and count newlines)
      local lines = 0
      local f = io.open(file, 'r')
      if f then
        for _ in f:lines() do
          lines = lines + 1
        end
        f:close()
        stats.total_lines = stats.total_lines + lines
        
        -- Map extension to language
        local language = M.extension_to_language(ext)
        if language then
          stats.languages[language] = {
            files = (stats.languages[language] and stats.languages[language].files or 0) + 1,
            lines = (stats.languages[language] and stats.languages[language].lines or 0) + lines
          }
        end
      end
    end
  end

  return stats
end

-- Map file extensions to language names
function M.extension_to_language(ext)
  local extensions = {
    ['py'] = 'Python',
    ['js'] = 'JavaScript',
    ['ts'] = 'TypeScript',
    ['jsx'] = 'React',
    ['tsx'] = 'React/TypeScript',
    ['lua'] = 'Lua',
    ['rs'] = 'Rust',
    ['go'] = 'Go',
    ['java'] = 'Java',
    ['cpp'] = 'C++',
    ['c'] = 'C',
    ['cs'] = 'C#',
    ['php'] = 'PHP',
    ['rb'] = 'Ruby',
    ['swift'] = 'Swift',
    ['kt'] = 'Kotlin',
    ['scala'] = 'Scala',
    ['sh'] = 'Shell',
    ['bash'] = 'Shell',
    ['zsh'] = 'Shell',
    ['fish'] = 'Shell',
    ['ps1'] = 'PowerShell',
    ['html'] = 'HTML',
    ['css'] = 'CSS',
    ['scss'] = 'Sass',
    ['sass'] = 'Sass',
    ['less'] = 'Less',
    ['json'] = 'JSON',
    ['yaml'] = 'YAML',
    ['yml'] = 'YAML',
    ['toml'] = 'TOML',
    ['xml'] = 'XML',
    ['sql'] = 'SQL',
    ['md'] = 'Markdown',
    ['txt'] = 'Text',
    ['dockerfile'] = 'Docker',
    ['vue'] = 'Vue',
    ['svelte'] = 'Svelte',
  }
  
  return extensions[ext:lower()]
end

return M