local wezterm = require('wezterm')
local config = wezterm.config_builder()

config.audible_bell = 'Disabled'
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {left = 8, right = 8, top = 8, bottom = 8}
config.initial_cols = 100
config.initial_rows = 25
config.font_size = 16.0
config.font = wezterm.font('Iosevka Extended')

config.color_scheme = 'Dark Pastel'
config.colors = {background = '#000000', foreground = '#ffffff'}

config.keys = {
    {key = 'j', mods = 'CMD', action = wezterm.action.SendString('\x1bj')},
    {key = 'о', mods = 'CMD', action = wezterm.action.SendString('\x1bj')},
    {key = 'k', mods = 'CMD', action = wezterm.action.SendString('\x1bk')},
    {key = 'л', mods = 'CMD', action = wezterm.action.SendString('\x1bk')},
    {key = 'l', mods = 'CMD', action = wezterm.action.SendString('\x1bl')},
    {key = 'д', mods = 'CMD', action = wezterm.action.SendString('\x1bl')},
    {key = ';', mods = 'CMD', action = wezterm.action.SendString('\x1b;')},
    {key = 'ж', mods = 'CMD', action = wezterm.action.SendString('\x1b;')}
}

return config
