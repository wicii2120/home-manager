{ pkgs, ... }:

{
  xdg.configFile."ghostty/config".text = ''
    bell-features = system,attention
    copy-on-select = true
    font-family = Maple Mono NF CN
    font-family = PingFang SC
    font-feature = calt, cv01, ss02, ss04, ss11
    font-size = 14
    font-style = light
    keybind = cmd+enter=unbind
    keybind = cmd+shift+v=paste_from_selection
    keybind = global:cmd+opt+shift+t=toggle_quick_terminal
    keybind = cmd+opt+shift+s=toggle_secure_input
    macos-option-as-alt = true
    macos-titlebar-style = tabs
    notify-on-command-finish = unfocused
    quick-terminal-screen = mouse
    shell-integration-features = cursor, sudo, title, ssh-env, path
    theme = Catppuccin Mocha
  '';
}
