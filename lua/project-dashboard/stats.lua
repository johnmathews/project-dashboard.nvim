local M = {}

-- Function to get file statistics
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