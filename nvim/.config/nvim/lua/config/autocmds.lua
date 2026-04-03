-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "advent",
  callback = function()
    vim.bo.commentstring = "// %s"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "neotodo", "markdown" },
  callback = function(ev)
    -- Disable cursortab completions for these filetypes
    local ok, cfg = pcall(function()
      return require("cursortab.config").get()
    end)
    if ok and cfg then
      local filetypes = cfg.behavior.ignore_filetypes
      for _, ft in ipairs(filetypes) do
        if ft == ev.match then
          return
        end
      end
      table.insert(filetypes, ev.match)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    -- Defer to run after lazy-loaded plugins (like obsidian.nvim) finish loading
    vim.schedule(function()
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
    end)
  end,
})
