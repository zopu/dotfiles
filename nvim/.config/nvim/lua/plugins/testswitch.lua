return {
  "zopu/testswitch.nvim",
  -- dir = "~/code/nvim/plugins/testswitch.nvim",
  opts = {},
  keys = {
    {
      "gt",
      function()
        require("testswitch").switch()
      end,
    },
  },
}
