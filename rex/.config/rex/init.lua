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

-- Tabs that run one program (lazygit, the apps picker below), opened in the focused
-- pane's directory. The app is switched to the new tab, and back to the tab it was
-- opened from when the program exits or the tab is closed.

-- Seconds to wait before switching to the new tab, so the app has received it first.
-- Lower is snappier; raise it if you land on the wrong tab (e.g. on a slow remote link).
local TAB_SWITCH_DELAY = "0.1"

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

-- When a program tab's program exits, its pane runs this action (through the rex CLI,
-- aimed at the app that opened it) to show the tab it was opened from. The program's
-- tab then closes in the background. client.tab.goto by position works on remote
-- servers too.
rex.action{
  name  = "tab_return",
  title = "Return to Previous Tab",
  args  = { window_id = "string" },
  run   = function(ctx, args)
    local index = tab_index(args.window_id)
    if index then pcall(rex.client.queue, "client.tab.goto", { index = index }) end
  end,
}

-- Runs "$@" and then tab_return. $1 = the app to switch, $2 = the tab to go back to.
-- Uses the rex CLI that Rex puts in every pane ($REX_BIN_DIR), so it also works in
-- panes on a remote server. The trap covers the tab being closed (cmd+w etc.), which
-- hangs up the pane.
local RETURN_WRAPPER = [[
client=$1 origin=$2
shift 2
ret() {
  rex="${REX_BIN_DIR:+$REX_BIN_DIR/}rex"
  "$rex" -C "$client" do -s "$REX_SESSION" tab_return window_id="$origin" </dev/null >/dev/null 2>&1
}
trap 'ret; exit 0' HUP TERM
"$@"
trap - HUP TERM
ret
exit 0
]]

-- Opens a tab running argv in cwd. Returning needs both the tab it came from and the
-- app to switch; without them the tab just runs argv. The app is ctx.client_id unless
-- given: an action run through the CLI (rex -C APP do ...) gets the CLI's own,
-- short-lived connection as ctx.client_id, so its caller has to name the app.
local function open_program_tab(ctx, argv, cwd, label, origin_window, client_id)
  client_id = client_id or ctx.client_id
  local command = argv
  if origin_window and client_id then
    command = { "sh", "-c", RETURN_WRAPPER, "sh", client_id, origin_window }
    for _, a in ipairs(argv) do command[#command + 1] = a end
  end
  local w, err = rex.session.new_window{
    window_label = label,
    layout = rex.layout.block{
      flavor = TERMINAL .. ".shell",
      options = { command = command, cwd = cwd },
    },
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
  rex.exec({ "sleep", TAB_SWITCH_DELAY }, { timeout = 2 })
  return { window_id = w.window_id, cwd = cwd, index = index }
end

-- The window (tab) a block is in, or nil.
local function block_window(block_id)
  if not block_id then return nil end
  local d = rex.session.describe_block{ block_id = block_id }
  return d and d.block and d.block.window_id
end

-- tmux.conf:98 bind-key g new-window -n lazygit -c "#{pane_current_path}" "lazygit"
rex.action{
  name  = "lazygit",
  title = "Open lazygit Tab",
  run   = function(ctx, args)
    return open_program_tab(ctx, { "lazygit" }, block_dir(ctx.block_id), "lazygit",
      block_window(ctx.block_id))
  end,
}
rex.bind("ctrl+]>g", "lazygit")

-- tmux.conf:100 bind-key c new-window
rex.bind("ctrl+]>c", "client.tab.new")

-- tmux.conf:83 bind-key T: toggle between the todo list and wherever you were.
-- The list is the first tab of the local session labelled "todo". On it, this goes
-- back to the session and tab it was opened from; anywhere else, it remembers where
-- you are and shows the list. Does nothing if there's no "todo" session, or if
-- there's nowhere to go back to (the memory is cleared when the config reloads).
local TODO_SESSION = "todo"
local todo_previous -- { session_id, window_id } of the tab the list was opened from

local function current_window(ctx)
  local window_id = block_window(ctx.block_id)
  if window_id then return window_id end
  local view = rex.session.view{}
  return view and view.active_window_id
end

rex.action{
  name  = "todo_toggle",
  title = "Toggle Todo List",
  keywords = "todo list tasks",
  run   = function(ctx, args)
    local list = rex.call("session.list")
    local todo_session
    for _, s in ipairs(list and list.sessions or {}) do
      if s.label == TODO_SESSION then todo_session = s.session_id; break end
    end
    if not todo_session then return end
    local view = rex.session.view{ session_id = todo_session }
    local todo_window = view and view.windows and view.windows[1] and view.windows[1].window_id
    if not todo_window then return end

    local here = current_window(ctx)
    if ctx.session_id == todo_session and here == todo_window then
      if todo_previous then
        pcall(rex.client.queue, "session.select", todo_previous)
      end
    else
      todo_previous = { session_id = ctx.session_id, window_id = here }
      pcall(rex.client.queue, "session.select",
        { session_id = todo_session, window_id = todo_window })
    end
  end,
}
-- kanata hold-w + t sends ctrl+] shift+t
rex.bind("ctrl+]>shift+t", "todo_toggle")

-- Git worktree sessions (palette only, no keys). Each opens a floating pane, like tmux's
-- display-popup, in the focused pane's directory, running a script from ~/scripts
-- (~/dotfiles/scripts/scripts). The pane closes when the script succeeds, and waits
-- for Enter when it fails so the error can be read.
-- Any further arguments are passed to the script as $1, $2, ...
local function open_popup(ctx, label, bounds, script, ...)
  local _, err = rex.session.new_layer{
    window_id = block_window(ctx.block_id),
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
]], "sh", ... },
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

-- tmux.conf:102 bind-key n: pick a command from the common apps cheat sheet with navi
-- in a floating pane, and run it in a new tab in the focused pane's directory, like
-- `tmux new-window -c "#{pane_current_path}" zsh -ci "{}"`. The sheet is the Rex copy
-- beside this file, which leaves out the tmux-only entries. The popup's shell finds it,
-- not this file: in a session on a Rex host the popup runs there, where this machine's
-- $HOME means nothing. A host without the rex package stowed falls back to navi's copy.

-- Run by the picker through the rex CLI, aimed at the app. client names that app again
-- for the tab's return trip (see open_program_tab).
rex.action{
  name  = "app_tab",
  title = "Open App Tab",
  args  = { command = "string", cwd = "string?", window_id = "string?", client = "string?" },
  run   = function(ctx, args)
    local origin = args.window_id ~= "" and args.window_id or nil
    return open_program_tab(ctx, { "zsh", "-ci", args.command }, args.cwd, nil, origin,
      args.client)
  end,
}

rex.action{
  name     = "apps",
  title    = "Open App…",
  keywords = "navi apps common launcher",
  description = "Pick a command from the common apps cheat sheet and run it in a new tab.",
  run = function(ctx, args)
    if not ctx.client_id then error("run this from the Rex app", 0) end
    -- $1 = the app, $2 = the tab to return to.
    open_popup(ctx, "Apps", { 0.1, 0.1, 0.8, 0.7 }, [[
sheet="$HOME/.config/rex/common_apps.cheat"
[ -e "$sheet" ] || sheet="$HOME/.config/navi/cheats/common_apps.cheat"
cmd=$(navi --path "$sheet" --print) || exit 0
[ -n "$cmd" ] || exit 0
rex="${REX_BIN_DIR:+$REX_BIN_DIR/}rex"
"$rex" -C "$1" do -s "$REX_SESSION" app_tab command="$cmd" cwd="$PWD" window_id="$2" client="$1" >/dev/null]],
      ctx.client_id, block_window(ctx.block_id) or "")
  end,
}
-- kanata hold-w + n sends ctrl+] n
rex.bind("ctrl+]>n", "apps")
