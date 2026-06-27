#!/usr/bin/env bash

# AeroSpace workspace indicator plugin for SketchyBar
# Highlights the currently focused workspace

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on
  else
    sketchybar --set $NAME background.drawing=off
  fi
fi

workspace="$(echo $NAME | cut -d '.' -f 2)"
apps="$(aerospace list-windows --workspace $workspace | cut -d '|' -f 2 | sort -u)"
focused="$(aerospace list-workspaces --focused)"
if [ "${apps}" != "" ]; then
  while read -r app; do
    app_trimmed="$(echo "$app" | xargs)"
    icon_strip+="$($CONFIG_DIR/plugins/icon_map_fn.sh "$app_trimmed")"
  done <<<"${apps}"
  sketchybar --set $NAME drawing=on icon="$workspace" label="$icon_strip" icon.drawing=on label.drawing=on
elif [ "$workspace" = "$focused" ]; then
  # Empty but focused: keep just the number visible as an indicator
  sketchybar --set $NAME drawing=on icon="$workspace" label="" icon.drawing=on label.drawing=off
else
  # Empty and unfocused: collapse the whole item so it leaves no gap
  sketchybar --set $NAME drawing=off
fi

