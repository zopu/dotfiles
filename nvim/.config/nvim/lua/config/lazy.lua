local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import any extras modules here
    -- { import = "lazyvim.plugins.extras.lang.typescript" },
    -- { import = "lazyvim.plugins.extras.lang.json" },
    -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

require("dap").configurations.go = {
  {
    name = "Debug N4J Import",
    type = "delve",
    request = "launch",
    program = "${workspaceFolder}/cmd/import/import.go",
    dlvToolPath = vim.fn.exepath("dlv"), -- Adjust this path if necessary
  },
  {
    name = "Debug API Server",
    type = "delve",
    request = "launch",
    program = "${workspaceFolder}/cmd/api/api.go",
    dlvToolPath = vim.fn.exepath("dlv"), -- Adjust this path if necessary
  },
}

local luasnip = require("luasnip")
local s, sn = luasnip.snippet, luasnip.snippet_node
local t, i, d = luasnip.text_node, luasnip.insert_node, luasnip.dynamic_node

local function uuid()
  local id, _ = vim.fn.system("uuidgen"):gsub("\n", "")
  return id
end

luasnip.add_snippets("global", {
  s({
    trig = "uuid",
    name = "UUID",
    dscr = "Generate a unique UUID",
  }, {
    d(1, function()
      return sn(nil, i(1, uuid()))
    end),
  }),
})
