-- Pull in the wezterm API
local wezterm = require 'wezterm'


function scheme_for_appearance(appearance)
  if appearance:find "Dark" then
    return "Catppuccin Frappe"
  else
    return "Catppuccin Latte"
  end
end

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = scheme_for_appearance(wezterm.gui.get_appearance())

config.font_size = 16.0
-- and finally, return the configuration to wezterm
return config
