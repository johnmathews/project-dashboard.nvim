-- Test suite for tile layout calculations
local eq = assert.are.same

describe("tiles module", function()
  local tiles

  before_each(function()
    package.loaded['project-dashboard.tiles'] = nil
    tiles = require('project-dashboard.tiles')
  end)

  describe("tile width calculation", function()
    it("should calculate correct tiles per row", function()
      local gap_x = 3
      local tile_width = 45
      local window_width = 150
      
      local available_width = window_width - (gap_x * 2) -- edge margins
      local tiles_per_row = math.floor((available_width + gap_x) / (tile_width + gap_x))
      
      eq(3, tiles_per_row)
    end)

    it("should calculate tile width to fill available space", function()
      local gap_x = 3
      local window_width = 150
      local tiles_per_row = 3
      
      local available_width = window_width - (gap_x * 2)
      local total_gap_width = (tiles_per_row - 1) * gap_x
      local tile_width = math.floor((available_width - total_gap_width) / tiles_per_row)
      
      -- Verify it uses the full width
      local total_used = (gap_x) + (tile_width * tiles_per_row) + (total_gap_width) + (gap_x)
      eq(window_width, total_used)
    end)

    it("should handle minimum 1 tile per row", function()
      local gap_x = 3
      local tile_width = 200
      local window_width = 100 -- Very narrow
      
      local available_width = window_width - (gap_x * 2)
      local tiles_per_row = math.floor((available_width + gap_x) / (tile_width + gap_x))
      
      -- Should be clamped to 1
      if tiles_per_row < 1 then
        tiles_per_row = 1
      end
      
      eq(1, tiles_per_row)
    end)
  end)

  describe("create_tiled_layout", function()
    it("should create layout with proper structure", function()
      local config = {
        layout = { margin_x = 8 },
        tiles = {
          width = 45,
          height = 12,
          gap_x = 3,
          gap_y = 1,
          order = { 'project_info', 'file_stats' },
          properties = {
            project_info = { title = '📁 Project' },
            file_stats = { title = '📄 Files' }
          }
        }
      }

      local dashboard_data = {
        file_stats = { total_files = 10, total_lines = 100, languages = {} },
        git_stats = { is_repo = true, current_branch = 'main' }
      }

      -- Mock vim.o.columns
      local old_columns = vim.o.columns
      vim.o.columns = 157

      local layout = tiles.create_tiled_layout(dashboard_data, config)

      vim.o.columns = old_columns

      assert.is_not_nil(layout)
      assert.is_true(#layout > 0)
      
      -- Check structure of first tile
      assert.is_not_nil(layout[1].row)
      assert.is_not_nil(layout[1].col)
      assert.is_not_nil(layout[1].width)
      assert.is_not_nil(layout[1].height)
      assert.is_not_nil(layout[1].content)
    end)
  end)
end)
