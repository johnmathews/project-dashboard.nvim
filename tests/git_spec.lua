-- Test suite for git functionality
local eq = assert.are.same

describe("git module", function()
  local git

  before_each(function()
    package.loaded['project-dashboard.git'] = nil
    git = require('project-dashboard.git')
  end)

  describe("GitHub remote detection", function()
    it("should parse SSH GitHub URLs", function()
      local test_cases = {
        {
          url = "git@github.com:owner/repo.git",
          expected_owner = "owner",
          expected_repo = "repo"
        },
        {
          url = "git@github.com:user-name/repo-name.git",
          expected_owner = "user-name",
          expected_repo = "repo-name"
        }
      }

      for _, test in ipairs(test_cases) do
        local owner, repo = test.url:match('github%.com[:/]([^/]+)/([^/]+)%.git')
        eq(test.expected_owner, owner)
        eq(test.expected_repo, repo)
      end
    end)

    it("should parse HTTPS GitHub URLs", function()
      local test_cases = {
        {
          url = "https://github.com/owner/repo.git",
          expected_owner = "owner",
          expected_repo = "repo"
        },
        {
          url = "https://github.com/user-name/repo-name.git",
          expected_owner = "user-name",
          expected_repo = "repo-name"
        }
      }

      for _, test in ipairs(test_cases) do
        local owner, repo = test.url:match('github%.com[:/]([^/]+)/([^/]+)%.git')
        eq(test.expected_owner, owner)
        eq(test.expected_repo, repo)
      end
    end)

    it("should handle URLs without .git extension", function()
      local url = "https://github.com/owner/repo"
      local owner, repo = url:match('github%.com[:/]([^/]+)/([^/%.]+)')
      eq("owner", owner)
      eq("repo", repo)
    end)
  end)

  describe("get_git_stats_async", function()
    it("should return stats object", function()
      local called = false
      local stats

      git.get_git_stats_async(function(status, data)
        if status == 'complete' then
          called = true
          stats = data
        end
      end)

      -- Wait for async callback
      vim.wait(1000, function()
        return called
      end)

      assert.is_true(called)
      assert.is_not_nil(stats)
      assert.is_boolean(stats.is_repo)
    end)
  end)
end)
