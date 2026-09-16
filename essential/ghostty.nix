{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    settings = {
      copy-on-select = true;
      notify-on-command-finish = "unfocused";
      quick-terminal-screen = "mouse";
      font-family = [
        "Maple Mono NF CN"
        "PingFang SC"
      ];
      font-style = "light";
      font-size = 14;
      font-feature = "calt, cv01, ss02, ss04, ss11";
      theme = "Catppuccin Mocha";
      shell-integration-features = "cursor, sudo, title, ssh-env, path";
      macos-option-as-alt = true;
      macos-titlebar-style = "tabs";
      bell-features = "system,attention";
      keybind = [
        "cmd+enter=unbind"
        "cmd+shift+v=paste_from_selection"
        "global:cmd+opt+shift+t=toggle_quick_terminal"
        "cmd+opt+shift+s=toggle_secure_input"
      ];
    };
  };

}
