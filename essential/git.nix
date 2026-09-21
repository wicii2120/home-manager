{ pkgs, ... }:

{
  home.packages = with pkgs; [
    glab
  ];

  home.shellAliases = {
    lzg = "lazygit";
  };

  programs.git = {
    enable = true;
    ignores = [
      "*~"
      "*.swp"
      "DS_Store"
    ];
    lfs.enable = true;
    settings = {
      core = {
        ignorecase = false;
      };
      pull = {
        rebase = true;
      };
      merge = {
        tool = "nvim";
        conflictStyle = "zdiff3";
      };
      diff = {
        tool = "nvim";
      };
      "difftool \"nvim\"" = {
        cmd = "nvim -d -- $LOCAL $REMOTE";
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      line-numbers = true;
      syntax-theme = "Catppuccin Mocha";
      hyperlinks = true;
    };
  };

  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-dash
    ];
    hosts = {
      "github.com" = {
        user = "wicii2120";
      };
    };
    settings = {
      editor = "nvim";
      git_protocol = "https";
    };
  };

  programs.lazygit = {
    enable = true;
    settings = {
      gui = {
        scrollHeight = 12;
        scrollPastBottom = false;
        scrollOffMargin = 4;
      };
      git = {
        diffRenderers = [
          { command = "delta --paging=never --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\""; }
        ];
      };
      os = {
        editPreset = "nvim";
      };
      services = {
        "gitlab.tianhe-tech.com" = "gitlab:gitlab.tianhe-tech.com";
      };
    };
  };
}
