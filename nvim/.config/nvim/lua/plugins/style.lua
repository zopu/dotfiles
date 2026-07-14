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
      -- Neovim 0.12 ships a built-in colorscheme literally named "catppuccin"
      -- that is NOT the catppuccin-nvim plugin. With colorscheme = "catppuccin"
      -- Neovim loads its built-in one, which shadows the plugin and applies only
      -- base colors -- the plugin's per-level @markup.heading.N.markdown rainbow
      -- groups never load, so `#`/`##`/`###` all render the same blue. The
      -- plugin now registers itself as "catppuccin-nvim"; load that instead.
      -- See: https://github.com/LazyVim/LazyVim/discussions/7085
      colorscheme = "catppuccin-nvim",
    },
  },
}
