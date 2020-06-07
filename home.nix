{ config, pkgs, ... }:

let

  xmonad = pkgs.xmonad-with-packages.override {
    packages = p: with p; [ xmonad-contrib xmonad-extras ];
  };

in

{
  imports = [
    /home/asa/git/vital-nix/user/feh-background.nix
    /home/asa/git/vital-nix/user/p53.nix
  ];

  home = {
    file = {
      ".xmonad/xmonad.hs".source = ./xmonad.hs;
      ".zshrc".source = ./zshrc;
      ".zprofile".source = ./zprofile;
    };

    packages = with pkgs; [
      zsh-prezto
      neovim
      google-chrome
      firefox
      file
      exa
      silver-searcher
      inkscape
      gimp
      glxinfo
      sublime-merge
    ];

    sessionVariables = {
      EDITOR = "nvim";
      TERM = "xterm-256color";
    };

    stateVersion = "20.03";
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    home-manager.enable = true;

    git = {
      package = pkgs.gitAndTools.gitFull;
      enable = true;
      extraConfig = {
        core.editor = "$EDITOR";
      };
    };

    jq.enable = true;

    kitty = {
      enable = true;
      settings = {
        foreground = "#f8f8f2";
        background = "#272822";
        selection_foreground = "#f8f8f2";
        selection_background = "#49483e";
        font_family = "Fira Code Retina";
        font_size = "9";
        visual_bell_duration = "0.05";
        term = "xterm-256color";
      };
    };

    man.enable = true;
  };


  xdg.configFile = {
    "nvim/init.vim".source = ./nvim/init.vim;
    "polybar/config".source = ./polybar;
  };

  xresources.properties = {
    # special
    "*.foreground"  = "#d1d1d1";
    # *.background:   #221e2d
    "*.cursorColor" = "#d1d1d1";

    # black
    "*.color0"   = "#272822";
    "*.color8"   = "#75715e";

    # red
    "*.color1"   = "#f92672";
    "*.color9"   = "#f92672";

    # green
    "*.color2"   = "#a6e22e";
    "*.color10"  = "#a6e22e";

    # yellow
    "*.color3"   = "#f4bf75";
    "*.color11"  = "#f4bf75";

    # blue
    "*.color4"   = "#66d9ef";
    "*.color12"  = "#66d9ef";

    # magenta
    "*.color5"   = "#ae81ff";
    "*.color13"  = "#ae81ff";

    # cyan
    "*.color6"   = "#a1efe4";
    "*.color14"  = "#a1efe4";

    # white
    "*.color7"   = "#f8f8f2";
    "*.color15"  = "#f9f8f5";

    "Xft.dpi"       = 192;
    "Xft.antialias" = true;
    "Xft.hinting"   = true;
    "Xft.rgba"      = "rgb";
    "Xft.autohint"  = false;
    "Xft.hintstyle" = "hintslight";
    "Xft.lcdfilter" = "lcddefault";

    "*termname"           = "xterm-256color";
    "dmenu.selforeground" = "#FFFFFF";
    "dmenu.background"    = "#000000";
    "dmenu.selbackground" = "#0C73C2";
    "dmenu.foreground"    = "#A0A0A0";
  };

  xsession = {
    enable = true;

    windowManager.command = "${xmonad}/bin/xmonad";
  };
}