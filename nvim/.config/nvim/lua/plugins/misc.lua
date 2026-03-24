local actions = require("fzf-lua").actions
return {
  {
    "ibhagwan/fzf-lua",
    opts = {
      -- Using alt- as a prefix for aerospace so need to remap things here
      actions = {
        files = {
          true, -- inherit defaults
          ["ctrl-h"] = actions.toggle_hidden,
        },
      },
    },
  },
}
