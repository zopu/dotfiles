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
        enabled = false,
      },
    },
  },
  {
    "cursortab/cursortab.nvim",
    -- version = "*",  -- Use latest tagged version for more stability
    lazy = false, -- The server is already lazy loaded
    build = "cd server && go build",
    config = function()
      require("cursortab").setup({
        provider = {
          type = "mercuryapi",
          api_key_env = "MERCURY_AI_TOKEN",
        },
        keymaps = {
          accept = "<C-y>",
          partial_accept = false,
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      -- Let cursortab own <C-y> for accepting its ghost-text suggestions.
      opts.keymap["<C-y>"] = {}
      opts.keymap["<Tab>"] = {
        function(cmp)
          if cmp.snippet_active() then
            return cmp.accept()
          elseif cmp.is_visible() then
            return cmp.select_and_accept()
          else
            return cmp.show()
          end
        end,
        "snippet_forward",
        "fallback",
      }
      opts.keymap["<S-Tab>"] = { "snippet_backward", "fallback" }
    end,
  },
}
