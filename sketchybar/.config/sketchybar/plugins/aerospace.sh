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
apps="$(aerospace list-windows --workspace $workspace | cut -d '|' -f 2)"
space="$(echo "$INFO" | jq -r '.space')"
# apps="$(echo "$INFO" | jq -r '.apps | keys[]')"
if [ "${apps}" != "" ]; then
  num_label="$(echo $workspace)"
  while read -r app; do
    app_trimmed="$(echo "$app" | xargs)"
    icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app_trimmed")"
  done <<<"${apps}"
  sketchybar --set $NAME icon="$num_label" label="$icon_strip" icon.drawing=on label.drawing=on
else
  sketchybar --set $NAME icon="" label="" icon.drawing=off label.drawing=off
fi

