-- Test suite for project-dashboard initialization
local eq = assert.are.same

describe("project-dashboard", function()
  local dashboard

  before_each(function()
    -- Clear any cached modules
    package.loaded['project-dashboard'] = nil
    package.loaded['project-dashboard.init'] = nil
    dashboard = require('project-dashboard')
  end)

  describe("setup", function()
    it("should load without errors", function()
      local ok = pcall(function()
        dashboard.setup({})
      end)
      assert.is_true(ok)
    end)

    it("should merge user config with defaults", function()
      dashboard.setup({
        auto_open = false,
        layout = {
          margin_x = 12
        }
      })
      
      eq(false, dashboard.config.auto_open)
      eq(12, dashboard.config.layout.margin_x)
      -- Default should still be present
      assert.is_not_nil(dashboard.config.show_timing)
    end)

    it("should create ProjectDashboard command", function()
      dashboard.setup({})
      local commands = vim.api.nvim_get_commands({})
      assert.is_not_nil(commands.ProjectDashboard)
    end)
  end)

  describe("is_git_repo", function()
    it("should detect git repository", function()
      -- This test assumes we're in a git repo
      local is_repo = dashboard.is_git_repo()
      assert.is_boolean(is_repo)
    end)
  end)
end)
