-- Pull in the wezterm API
local wezterm = require("wezterm")
local focus = require("focus")

-- This table will hold the configuration.
local config = {}
focus.apply_to_config(config)

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

config.enable_tab_bar = false
config.window_decorations = "RESIZE"
config.color_scheme = "Catppuccin Mocha"

config.font_size = 13.0
config.font = wezterm.font_with_fallback({ "SFMono Nerd Font" })
config.window_padding = {
	left = 15,
	right = 15,
	top = 10,
	bottom = 5,
}

local bg = {
	source = {
		Gradient = {
			colors = { "#000000", "#110022" },
		},
	},
	width = "100%",
	height = "100%",
	opacity = 0.9,
}

-- config.background = {bg}

-- and finally, return the configuration to wezterm
return config
