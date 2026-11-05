-- Rex config migrated from tmux (~/.config/tmux/tmux.conf).
-- Ghostty, WezTerm and Alacritty contributed no bindings.

-- tmux prefix ctrl+]: pass it through to programs when pressed twice.
rex.bind("ctrl+]>ctrl+]", "pane.send_key", { key = "ctrl+]" })

-- Repeat mode for tmux `bind -r` bindings: ctrl+] then ctrl+r enters, enter/escape leaves.
rex.mode("repeat", { exclusive = true })
rex.bind("ctrl+]>ctrl+r", "client.mode.enter", { name = "repeat" })
rex.bind("repeat/enter", "client.mode.exit")
rex.bind("repeat/escape", "client.mode.exit")

-- tmux.conf:15 bind -r r source-file ~/.config/tmux/tmux.conf
rex.bind("ctrl+]>r", "client.config.reload")
rex.bind("repeat/r", "client.config.reload")

-- tmux.conf:94 bind-key o next-window
rex.bind("ctrl+]>o", "client.tab.next")
-- Inverse of the above (not from tmux.conf; added by request)
rex.bind("ctrl+]>i", "client.tab.previous")
-- tmux's default prefix+p (previous-window); kanata's tmux layer sends ctrl+] p for hold-w + i
rex.bind("ctrl+]>p", "client.tab.previous")

-- tmux.conf:95 bind-key I swap-window -t -1\; select-window -t -1
rex.bind("ctrl+]>shift+i", "client.tab.move", { direction = "backward" })

-- tmux.conf:96 bind-key O swap-window -t +1\; select-window -t +1
rex.bind("ctrl+]>shift+o", "client.tab.move", { direction = "forward" })

-- tmux.conf:79 session switcher (kanata hold-w + , sends ctrl+] ctrl+e); cmd+k also opens it
rex.bind("ctrl+]>ctrl+e", "session.switch")

-- Shared helpers for the custom actions below.
local TERMINAL = "com.superlogical.terminal"

-- A terminal block's working directory: the one its shell reported (OSC 7), else the
-- foreground process's cwd from the OS. nil if neither is known.
local function block_dir(block_id)
  if not block_id then return nil end
  local dir
  local r = rex.block.call(TERMINAL, "pwd", { block_id = block_id })
  if r and type(r.pwd) == "string" and r.pwd ~= "" then
    dir = r.pwd:gsub("^file://[^/]*", "")
  else
    local p = rex.block.call(TERMINAL, "process", { block_id = block_id })
    dir = p and ((p.foreground and p.foreground.cwd) or (p.child and p.child.cwd))
  end
  if type(dir) == "string" and dir ~= "" then return dir end
  return nil
end

-- tmux.conf:98 bind-key g new-window -n lazygit -c "#{pane_current_path}" "lazygit"
-- Opens a tab labelled "lazygit" running lazygit in the focused pane's directory.
-- Seconds to wait before switching to the new tab, so the app has received it first.
-- Lower is snappier; raise it if you land on the wrong tab (e.g. on a slow remote link).
local LAZYGIT_TAB_SWITCH_DELAY = "0.1"

-- The 1-based tab position of a window in this session, or nil if it is gone.
local function tab_index(window_id)
  local view = rex.session.view{}
  if view and view.windows then
    for i, win in ipairs(view.windows) do
      if win.window_id == window_id then return i end
    end
  end
  return nil
end

-- When lazygit exits, its pane runs this action (through the rex CLI, aimed at the app
-- that opened it) to show the tab lazygit was opened from. The lazygit tab then closes
-- in the background. client.tab.goto by position works on remote servers too.
rex.action{
  name  = "lazygit_return",
  title = "Return from lazygit Tab",
  args  = { window_id = "string" },
  run   = function(ctx, args)
    local index = tab_index(args.window_id)
    if index then pcall(rex.client.queue, "client.tab.goto", { index = index }) end
  end,
}

rex.action{
  name  = "lazygit",
  title = "Open lazygit Tab",
  run   = function(ctx, args)
    local options = { command = { "lazygit" } }
    -- Remember the tab this was opened from, so closing lazygit can return to it.
    local origin_window
    if ctx.block_id then
      local d = rex.session.describe_block{ block_id = ctx.block_id }
      origin_window = d and d.block and d.block.window_id
    end
    if origin_window and ctx.client_id then
      -- $1 = the app to switch, $2 = the tab to go back to. Uses the rex CLI that Rex puts
      -- in every pane ($REX_BIN_DIR), so it also works in panes on a remote server.
      -- The trap covers the tab being closed (cmd+w etc.), which hangs up the pane.
      options.command = { "sh", "-c", [[
ret() {
  rex="${REX_BIN_DIR:+$REX_BIN_DIR/}rex"
  "$rex" -C "$1" do -s "$REX_SESSION" lazygit_return window_id="$2" </dev/null >/dev/null 2>&1
}
trap 'ret "$1" "$2"; exit 0' HUP TERM
lazygit
trap - HUP TERM
ret "$1" "$2"
exit 0
]], "sh", ctx.client_id, origin_window }
    end
    options.cwd = block_dir(ctx.block_id)
    local w, err = rex.session.new_window{
      window_label = "lazygit",
      layout = rex.layout.block{ flavor = TERMINAL .. ".shell", options = options },
    }
    if err ~= nil then error(err, 0) end
    -- Ask the app to show the new tab by its position. client.tab.goto works on remote
    -- servers too, unlike session.select, which looks the session up on the local server.
    -- Needs Remote Control on in Rex's settings; skipped when no client ran the action.
    local index = tab_index(w.window_id) or -1
    pcall(rex.client.queue, "client.tab.goto", { index = index })
    -- Queued actions run once run returns. Wait briefly so the app has received the new
    -- tab first; otherwise it switches to the tab that was last before. (rex.sleep isn't
    -- available in config actions; rex.exec doesn't block the server.)
    rex.exec({ "sleep", LAZYGIT_TAB_SWITCH_DELAY }, { timeout = 2 })
    return { window_id = w.window_id, cwd = options.cwd, index = index }
  end,
}
rex.bind("ctrl+]>g", "lazygit")

-- tmux.conf:100 bind-key c new-window
rex.bind("ctrl+]>c", "client.tab.new")

-- Git worktree sessions (palette only, no keys). Each opens a floating pane, like tmux's
-- display-popup, in the focused pane's directory, running a script from ~/scripts
-- (~/dotfiles/scripts/scripts). The pane closes when the script succeeds, and waits
-- for Enter when it fails so the error can be read.
local function open_popup(ctx, label, bounds, script)
  local window_id
  if ctx.block_id then
    local d = rex.session.describe_block{ block_id = ctx.block_id }
    window_id = d and d.block and d.block.window_id
  end
  local _, err = rex.session.new_layer{
    window_id = window_id,
    bounds = bounds,
    focus = true,
    layout = rex.layout.block{
      flavor = TERMINAL .. ".shell",
      label = label,
      options = {
        cwd = block_dir(ctx.block_id),
        command = { "sh", "-c", script .. [[

status=$?
if [ "$status" -ne 0 ]; then
  printf '\nFailed (exit %s). Press Enter to close.' "$status"
  read -r _
fi
]] },
      },
    },
  }
  if err ~= nil then error(err, 0) end
end

rex.action{
  name     = "worktree_new",
  title    = "New Worktree Session",
  category = "Git",
  keywords = "git worktree branch session create",
  description = "Create a git worktree (if needed) and open a Rex session with a shell in it.",
  run = function(ctx, args)
    open_popup(ctx, "New worktree", { 0.2, 0.25, 0.6, 0.35 }, [[
printf 'Worktree name: '; read -r name
[ -n "$name" ] || exit 0
printf 'Branch [%s]: ' "$name"; read -r branch
"$HOME/scripts/rex-git-worktree-create.sh" "$name" "${branch:-$name}"]])
  end,
}

rex.action{
  name     = "worktree_open",
  title    = "Open Worktree Session",
  category = "Git",
  keywords = "git worktree branch session switch fzf",
  description = "Pick an existing git worktree and open its Rex session.",
  run = function(ctx, args)
    open_popup(ctx, "Open worktree", { 0.1, 0.1, 0.8, 0.7 }, [[
"$HOME/scripts/rex-git-worktree-open.sh"]])
  end,
}
