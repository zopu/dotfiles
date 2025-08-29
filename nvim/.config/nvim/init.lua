-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.diagnostic.config({ virtual_text = false })

-- vim.lsp.config['adv'] = {
--   -- Command and arguments to start the server.
--   cmd = { 'adv lsp' },
--   -- Filetypes to automatically attach to.
--   filetypes = { 'adv' },
--   -- Sets the "root directory" to the parent directory of the file in the
--   -- current buffer that contains either a ".luarc.json" or a
--   -- ".luarc.jsonc" file. Files that share a root directory will reuse
--   -- the connection to the same LSP server.
--   -- root_markers = { '.luarc.json', '.luarc.jsonc' },
--   -- Specific settings to send to the server. The schema for this is
--   -- defined by the server. For example the schema for lua-language-server
--   -- can be found here https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json
--   settings = {}
-- }
