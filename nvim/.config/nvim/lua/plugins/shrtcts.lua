return {
  "zopu/shrtcts.nvim",
  -- dir = "~/code/nvim/plugins/shrtcts.nvim",
  opts = {},
  keys = {
    {
      "<C-w>L",
      function()
        require("shrtcts").openBufInRhsWindow()
      end,
    },
    {
      "<C-w>H",
      function()
        require("shrtcts").openBufInLhsWindow()
      end,
    },
  },
}
