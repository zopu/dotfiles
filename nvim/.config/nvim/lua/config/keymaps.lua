-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- some emacs keybindings

-- backward-char
vim.keymap.set({ "!", "n" }, "<C-b>", "<Left>", { silent = true })

-- forward-char
vim.keymap.set({ "!", "n" }, "<C-f>", "<Right>", { silent = true })

-- previous-line
vim.keymap.set("i", "<C-p>", "<Up>", { silent = true })

-- next-line
vim.keymap.set("i", "<C-n>", "<Down>", { silent = true })
