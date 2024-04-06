return {
  {
    "catppuccin",
    opts = {
      transparent_background = true,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "andrew-george/telescope-themes",
    config = function()
      require("telescope").load_extension("themes")
    end,
  },
}
