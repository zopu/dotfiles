-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.o.termguicolors = true
-- vim.cmd("colorscheme catppuccin")
--
vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = true,
})
