-- Put this file at: ~/.config/nvim/lua/plugins/dashboard.lua
-- (and delete your old starter.lua so the two don't fight)

-- Nerd Font icons, built from codepoints so nothing gets lost when copy/pasting
local function icon(codepoint)
  return vim.fn.nr2char(codepoint) .. " "
end

-- A tiny helper for the two footer lines
local function footer_line(fmt)
  return function()
    local ok, lazy = pcall(require, "lazy")
    if not ok then
      return {}
    end
    local s = lazy.stats()
    return {
      align = "center",
      padding = 0,
      text = { { fmt(s), hl = "SnacksDashboardFooter" } },
    }
  end
end

return {
  -- 1. Tokyo Night (bundled with LazyVim, so no extra plugin needed)
  --    Variants: "tokyonight-night" (darkest navy), "tokyonight-storm" (lighter blue-grey),
  --    "tokyonight-moon" (softer, purple-ish)
  { "LazyVim/LazyVim", opts = { colorscheme = "tokyonight-night" } },

  -- 2. The dashboard (LazyVim uses snacks.nvim for this by default)
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts.dashboard = opts.dashboard or {}
      local d = opts.dashboard

      d.width = 28

      -- Cat header
      d.preset = d.preset or {}
      d.preset.header = table.concat({
        "  ／l、",
        "（ﾟ､ ｡ 7",
        "  l  ~ヽ",
        "  じしf_,)ノ",
      }, "\n")

      -- Menu items: icon, label, key
      d.preset.keys = {
        { icon = icon(0xf002), key = "f", desc = "Find Files", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = icon(0xf1da), key = "l", desc = "Load Session", action = ':lua require("persistence").load()' },
        { icon = icon(0xf15b), key = "n", desc = "New File", action = ":ene | startinsert" },
        {
          icon = icon(0xf017),
          key = "r",
          desc = "Open Recent File",
          action = ":lua Snacks.dashboard.pick('oldfiles')",
        },
        { icon = icon(0xf002), key = "s", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = icon(0xf1b2), key = "u", desc = "Update Plugins", action = ":Lazy update" },
        {
          icon = icon(0xf013),
          key = "c",
          desc = "Config",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        { icon = icon(0xf08b), key = "q", desc = "Quit", action = ":qa" },
      }

      -- Show keys as [f] [l] [n] ...
      d.formats = d.formats or {}
      d.formats.key = function(item)
        return {
          { "[", hl = "special" },
          { item.key, hl = "key" },
          { "]", hl = "special" },
        }
      end

      -- Layout: header, menu, then the two footer lines
      d.sections = {
        { section = "header", padding = 2 },
        { section = "keys", gap = 1, padding = 2 },
        footer_line(function(s)
          return string.format("Startuptime: %.6f ms", s.startuptime)
        end),
        footer_line(function(s)
          return string.format("Plugins: %d loaded / %d installed", s.loaded, s.count)
        end),
      }

      -- Tokyo Night palette
      local function set_hl()
        local set = vim.api.nvim_set_hl
        set(0, "SnacksDashboardHeader", { fg = "#7aa2f7" }) -- blue
        set(0, "SnacksDashboardIcon", { fg = "#7dcfff" }) -- cyan
        set(0, "SnacksDashboardDesc", { fg = "#c0caf5" }) -- light lavender text
        set(0, "SnacksDashboardKey", { fg = "#bb9af7" }) -- purple
        set(0, "SnacksDashboardSpecial", { fg = "#565f89" }) -- dim brackets
        set(0, "SnacksDashboardFooter", { fg = "#9ece6a", italic = true }) -- green
      end
      set_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hl })

      -- Startup time isn't final when the dashboard first draws, so redraw once it is
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function()
          vim.schedule(function()
            pcall(function()
              Snacks.dashboard.update()
            end)
          end)
        end,
      })

      return opts
    end,
  },
}
