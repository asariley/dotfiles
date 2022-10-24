{ config, pkgs, lib, ... }:

let

  xmonad = pkgs.xmonad-with-packages.override {
    packages = p: with p; [ xmonad-contrib xmonad-extras ];
  };
  mkOutOfStoreSymlink = path:
    let
      pathStr = toString path;
      name = lib.hm.strings.storeFileName (baseNameOf pathStr);
    in
      pkgs.runCommandLocal name {} ''ln -s ${lib.escapeShellArg pathStr} $out'';

in

{
  imports = [
    /home/asa/git/vital-nix/user/feh-background.nix
    /home/asa/git/vital-nix/user/thinkpad.nix
    /home/asa/git/vital-nix/user/software-workstation.nix
  ];

  home = {
    file = {
      ".xmonad/xmonad.hs".source = ./xmonad.hs;
      ".zshrc".source = ./zshrc;
      ".zprofile".source = ./zprofile;
      ".config/polybar/cal_remind.sh" = {
        executable = true;
        # if google refuses to authorize you may need a vital specific client_id. I can hook you up
        text = ''
          gcalcli agenda --nostarted --military --tsv today tomorrow | head -n 1 | cut -f 2,5 | sed 's/\t/ - /' | { read -r -t1 val && echo "$val" || echo 'NO MORE MEETINGS TODAY!' ; }
          gcalcli remind 0
        '';
      };
      ".config/battery_check.sh" = {
        executable = true;
        text = ''
          #! /usr/bin/env nix-shell
          #! nix-shell -i bash -p acpi dunst

          export DISPLAY=:0
          XAUTHORITY=/home/asa/.Xauthority

          percent=`acpi -b | grep -P -o '[0-9]+(?=%)'`
          if [ $percent -le 15 ]
          then
            dunstify -a "BATTERY LOW" -u critical "danger!" "Connect the power cable!"
          fi
          echo 'ran batt' >> /home/asa/cron.log
        '';
      };
    };

    packages = with pkgs; [
      nixos-option
      zsh-prezto
      neovim
      google-chrome
      firefox
      file
      slack
      zoom-us
      gotop
      binutils
      exa
      silver-searcher
      inkscape
      gimp
      glxinfo
      sublime-merge
      vimpc
      hicolor-icon-theme
      dunst
      gcalcli
      terraform
      unzip
      virt-manager
      bmap-tools
      screen
      remmina
      ripgrep
      delta
      lsd
      fd
      stdenv.cc
      glibc.dev
      linuxHeaders
      bat
      (writeShellScriptBin "bat-fzf-preview" ''
        target_line="$1"
        first_window_line="$(($target_line-$FZF_PREVIEW_LINES/2))"
        last_window_line="$(($target_line+$FZF_PREVIEW_LINES))"
        shift
        ${bat}/bin/bat --color=always --style=numbers --highlight-line=$target_line --line-range=$(($first_window_line<1?1:$first_window_line)):$(($last_window_line)) "$@"
      '')
      #(import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {})._1password-gui
    ];

    sessionVariables = {
      EDITOR = "nvim";
      TERM = "xterm-256color";
    };

    stateVersion = "20.03";
  };

  nixpkgs.config = import ./nixpkgs-config.nix;
  xdg.configFile."nixpkgs/config.nix".source = ./nixpkgs-config.nix;

  services = {
    mpd = {
      enable = true;
    };
    dunst = {
      enable = true;
      # details at https://github.com/dunst-project/dunst/blob/master/dunstrc
      settings = {
        global = {
          follow = "keyboard";
          geometry = "800x200-150-20";
          separator_height = 8;
          padding = 16;
          horizontal_padding = 16;
          corner_radius = 6;
          mouse_left_click = "do_action";
          mouse_middle_click = "close_all";
          mouse_right_click = "close_current";
          ellipsize = "end";
          vertical_alignment = "center";
          notification_height = 150;
          word_wrap = true;
          format = "<b>%a</b> - <i>%s</i>\\n%b";
          show_indicators = false;
          line_height = 2;
        };
      };
    };
  };

  programs = {
    home-manager.enable = true;

    git = {
      package = pkgs.gitAndTools.gitFull;
      enable = true;
      extraConfig = {
        core.editor = "$EDITOR";
        core.pager = "${pkgs.delta}/bin/delta";
        interactive.diffFilter = "${pkgs.delta}/bin/delta --color-only";
        add.interactive.useBuiltin = false;
        include.path = "${builtins.fetchurl "https://raw.githubusercontent.com/dandavison/delta/4c879ac1afca68a30c9a100bea2965b858eb1853/themes.gitconfig"}";
        delta = {
          features = "chameleon";
          navigate = true;
          light = false;
        };
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
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

    firefox = {
      profiles.asa = {
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.bookmarks.editDialog.confirmationHintShowCount" = 3;
          "browser.bookmarks.restore_default_bookmarks" = false;
          "browser.contentblocking.category" = "standard";
          "browser.ctrlTab.recentlyUserOrder" = false;
          "browser.discovery.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.hightlights" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.feeds.snippets" = false;
          "browser.newtabpage.activity-stream.feeds.topsites" = false;
          "browser.search.region" = "US";
          "browser.search.suggest.enabled" = false;
          "browser.tabs.loadInBackground" = false;
          "browser.urlbar.placeholderName" = "DuckDuckGo";
          "browser.urlbar.placeholderName.private" = "DuckDuckGo";
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
          "extensions.formautofill.addresses.enabled" = false;
          "ui.systemUsesDarkTheme"= 1;
        };
      };
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        1password-x-password-manager
      ];
    };
  };


  xdg.configFile = {
    "polybar/config".source = ./polybar;
    "lsd/config.yaml".source = ./lsd.yaml;
    nvim.source = mkOutOfStoreSymlink ./nvim;
  };
  xdg.dataFile."nvim/site/autoload/plug.vim".source = builtins.fetchurl "https://raw.githubusercontent.com/junegunn/vim-plug/8fdabfba0b5a1b0616977a32d9e04b4b98a6016a/plug.vim";

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

