{ ... }:

{
  # Replaces the whitespace settings that used to live in after/ftplugin/.
  # Neovim has built-in EditorConfig support and reads this from $HOME for any
  # file below it; projects that ship their own .editorconfig take precedence,
  # and `root = true` in one stops the search before it reaches this file.
  home.file.".editorconfig".text = ''
    root = true

    [*.go]
    indent_style = tab
    indent_size = 4
    tab_width = 4

    [*.{json,jsonp,geojson,mcmeta,webmanifest,ipynb}]
    indent_style = space
    indent_size = 2

    [*.{yml,yaml,eyaml,kyaml,kyml,mplstyle}]
    indent_style = space
    indent_size = 2

    # nvim's ft=nginx also covers nginx.conf, nginx*.conf and any .conf inside a
    # nginx/ directory.
    [{nginx.conf,nginx*.conf,*.nginx}]
    indent_style = space
    indent_size = 4

    [**/nginx/*.conf]
    indent_style = space
    indent_size = 4
  '';
}
