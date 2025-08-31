#!/usr/bin/env bash

# AeroSpace workspace indicator plugin for SketchyBar
# Highlights the currently focused workspace

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on
else
    sketchybar --set $NAME background.drawing=off
fi