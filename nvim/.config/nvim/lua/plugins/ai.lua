local claude_toggle_key = "<C-,>"
return {
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        tools = {
          claude = {
            cmd = { vim.fn.expand("~/.claude/local/claude") },
          },
        },
      },
      nes = {
        enabled = function(buf)
          local ft = vim.bo[buf].filetype
          return ft ~= "neotodo"
        end,
      },
    },
  },
  {
    "coder/claudecode.nvim",
    dependencies = { "folke/snacks.nvim" },
    keys = {
      { claude_toggle_key, "<cmd>ClaudeCodeFocus<cr>", desc = "Claude Code", mode = { "n", "x" } },
    },
    opts = {
      terminal_cmd = "~/.claude/local/claude", -- Point to local installation
      terminal = {
        ---@module "snacks"
        ---@type snacks.win.Config|{}
        snacks_win_opts = {
          position = "float",
          width = 0.95,
          height = 0.95,
          keys = {
            claude_hide = {
              claude_toggle_key,
              function(self)
                self:hide()
              end,
              mode = "t",
              desc = "Hide",
            },
          },
        },
      },
    },
  },
}
