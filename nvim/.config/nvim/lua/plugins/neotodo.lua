return {
  "zopu/neotodo",
  -- dir = "/Users/mikeperrow/code/neotodo",
  name = "neotodo",
  -- dev = true,
  config = function()
    require("neotodo").setup({
      keybinds = {
        add_task = "ta",
        focus_toggle = "tf",
        mark_done = "td",
        move_to_section = "ts",
        move_to_now = "tn",
        move_task = "tm",
      },
    })
  end,
}
