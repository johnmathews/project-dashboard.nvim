local M = {}

-- Function to get git statistics
function M.get_git_stats()
  local stats = {
    remotes = {},
    branches = {},
    total_commits = 0,
    contributors = {},
    current_branch = '',
    repo_name = '',
    owner = ''
  }

  -- Get current branch
  local current_branch_cmd = 'git rev-parse --abbrev-ref HEAD'
  local current_branch = vim.fn.system(current_branch_cmd):gsub('%s+', '')
  if vim.v.shell_error == 0 then
    stats.current_branch = current_branch
  end

  -- Get remotes
  local remotes_cmd = 'git remote -v'
  local remotes_output = vim.fn.system(remotes_cmd)
  if vim.v.shell_error == 0 then
    for line in remotes_output:gmatch('[^\r\n]+') do
      local name, url = line:match('^(%S+)%s+(%S+)')
      if name and url then
        table.insert(stats.remotes, { name = name, url = url })
        
        -- Extract owner and repo from GitHub URL
        if url:match('github%.com') then
          local owner, repo = url:match('github%.com[:/][^/]+/([^/]+)/([^/]+)%.git')
          if owner and repo then
            stats.owner = owner
            stats.repo_name = repo:gsub('%.git$', '')
          end
        end
      end
    end
  end

  -- Get branches
  local branches_cmd = 'git branch -a'
  local branches_output = vim.fn.system(branches_cmd)
  if vim.v.shell_error == 0 then
    for line in branches_output:gmatch('[^\r\n]+') do
      local branch = line:match('%*?%s*(%S+)')
      if branch then
        table.insert(stats.branches, branch)
      end
    end
  end

  -- Get total commits
  local commits_cmd = 'git rev-list --count HEAD'
  local commits_output = vim.fn.system(commits_cmd):gsub('%s+', '')
  if vim.v.shell_error == 0 then
    stats.total_commits = tonumber(commits_output) or 0
  end

  -- Get contributors
  local contributors_cmd = 'git shortlog -sn --all'
  local contributors_output = vim.fn.system(contributors_cmd)
  if vim.v.shell_error == 0 then
    for line in contributors_output:gmatch('[^\r\n]+') do
      local count, author = line:match('^(%d+)%s+(.+)$')
      if count and author then
        table.insert(stats.contributors, {
          name = author,
          commits = tonumber(count)
        })
      end
    end
  end

  return stats
end

-- Get GitHub repository info (public API)
function M.get_github_info(owner, repo, timeout)
  if not owner or not repo then
    return nil
  end

  timeout = timeout or 5000
  
  local curl_cmd = string.format(
    'curl -s --max-time %d "https://api.github.com/repos/%s/%s"',
    timeout / 1000,
    owner,
    repo
  )
  
  local output = vim.fn.system(curl_cmd)
  
  if vim.v.shell_error == 0 then
    local success, data = pcall(vim.json.decode, output)
    if success and data and not data.message then
      return {
        stars = data.stargazers_count or 0,
        forks = data.forks_count or 0,
        open_issues = data.open_issues_count or 0,
        language = data.language,
        description = data.description,
        created_at = data.created_at,
        updated_at = data.updated_at
      }
    end
  end
  
  return nil
end

return M