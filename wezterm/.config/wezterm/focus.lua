local wezterm = require("wezterm")

local module = {}

function module.apply_to_config(config) end

focused_bg = {
	source = {
		Gradient = {
			colors = { "#000000", "#110022" },
		},
	},
	width = "100%",
	height = "100%",
	opacity = 0.95,
}

inactive_bg = {
	source = {
		Gradient = {
			colors = { "#000000", "#221100" },
		},
	},
	width = "100%",
	height = "100%",
	opacity = 0.85,
}

wezterm.on("update-status", function(window, pane)
	local overrides = window:get_config_overrides() or {}
	if window:is_focused() then
		-- overrides.color_scheme = 'nordfox'
		-- overrides.window_background_opacity = 0.1
		-- overrides.background[0].opacity = 1.0
		overrides.background = { focused_bg }
	else
		overrides.background = { inactive_bg }
		-- overrides.color_scheme = 'nightfox'
		-- overrides.window_background_opacity = nil
		-- overrides.background[0].opacity = 0.0
	end
	window:set_config_overrides(overrides)
end)

-- return our module table
return module
