{ config, lib, pkgs, ... }:
let
  mod = "Mod4";
  solarized = import ../common/solarized.nix;
  # TODO pull this out into lib
  emacsclient = eval: pkgs.writeShellScript "emacsclient-eval" ''
    msg=$(emacsclient --eval '${eval}' 2>&1)
    echo "''${msg:1:-1}"
  '';
  screenlayout = {
    home = pkgs.writeShellScript "screenlayout_home.sh" ''
      xrandr \
        --output eDP1 --mode 3840x2160 --pos 0x0 --rotate normal \
        --output DP1 --primary --mode 3840x2160 --pos 0x2160 --rotate normal \
        --output DP2 --off --output DP3 --off --output VIRTUAL1 --off
    '';
  };
in {
  options = with lib; {
    system.machine.wirelessInterface = mkOption {
      description = ''
        Name of the primary wireless interface. Used by i3status, etc.
      '';
      default = "wlp3s0";
      type = types.str;
    };

    system.machine.i3FontSize = mkOption {
      description = "Font size to use in i3 window decorations etc.";
      default = 6;
      type = types.int;
    };
  };

  config = let
      decorationFont = "MesloLGSDZ ${toString config.system.machine.i3FontSize}";
      iconFont = "FontAwesome ${toString (config.system.machine.i3FontSize)}";
    in {
      nixpkgs.overlays = [
        (self: super: {
          i3status-rust = with (import (fetchTarball
            "https://github.com/nixos/nixpkgs/archive/master.tar.gz") { });
            rustPlatform.buildRustPackage rec {
              pname = "i3status-rust";
              version = "0.14.1-df1974dd313f6b50bf0f19f948698fc6cb20e8f3";

              src = pkgs.fetchFromGitHub {
                owner = "greshake";
                repo = "i3status-rust";
                rev = "df1974dd313f6b50bf0f19f948698fc6cb20e8f3";
                sha256 = "02q11a4ggackvdv8ls6cmiw5mjfnrb8505q4syfwfs0g5l4lhyjy";
              };
              cargoSha256 =
                "1bg82qnbmwb6jqxpz9kln0h52311c2gkqadpvs4cabrx3ghafp1g";
              nativeBuildInputs = [ pkgconfig ];
              buildInputs = [ dbus libpulseaudio ];
              doCheck = false;
            };
        })
      ];
      home.packages = with pkgs; [
        rofi
        rofi-pass

        i3status-rust
        font-awesome
        ethtool
        iw
        upower

        i3lock
        dconf # for gtk

        # Screenshots
        maim

        # GIFs
        picom
        peek
      ];

      ## See https://github.com/greshake/i3status-rust/blob/master/blocks.md
      ## for blocks configuration.
      home.file.".config/i3status.toml".text = ''
        theme = "space-villain"
        icons = "awesome5"
        interval = 2

        [[block]]
        block = "music"
        player = "spotify"
        buttons = ["play", "next"]

        [[block]]
        block = "net"
        format = "W: {ssid} {signal_strength} {speed_up} {speed_down} {graph_down}"
        device = "${config.system.machine.wirelessInterface}"
        interval = 5
        use_bits = false

        [[block]]
        block = "custom"
        on_click = "alacritty -e ${
          pkgs.writeShellScript "i3status-openvpn-urbint-on_click.sh" ''
            if systemctl is-active --quiet openvpn-urbint.service; then
              vpoff
            else
              vpon
            fi
          ''
        }"
        command = "${
          pkgs.writeShellScript "i3status-openvpn-urbint-command.sh" ''
            if systemctl is-active --quiet openvpn-urbint.service; then
              jq -n "{ icon: \"net_vpn\", state: \"Good\", text: \" On\" }"
            else
              jq -n "{ icon: \"net_vpn\", state: \"Idle\", text: \" Off\" }"
            fi
          ''
        }"
        interval = 30
        json = true

        [[block]]
        block = "memory"
        display_type = "memory"
        format_mem = "{Mug}G|"
        format_swap = "{SUp}%"
        icons = true
        clickable = true
        interval = 5
        warning_mem = 80
        warning_swap = 80
        critical_mem = 95
        critical_swap = 95

        [[block]]
        block = "cpu"
        interval = 1
        format = "{barchart} {utilization}% {frequency}GHz"

        [[block]]
        block = "load"
        interval = 1
        format = "{1m}"

        [[block]]
        block = "battery"
        driver = "upower"
        device = "DisplayDevice"
        format = "{percentage}% {time} {power}W"

        [[block]]
        block = "sound"
        driver = "auto"
        device = "default"
        format = "{output_name} {volume}"
        max_vol = 45
        [block.mappings]
        "alsa_output.pci-0000_00_1f.3.analog-stereo" = "🎧"

        [[block]]
        block = "pomodoro"
        length = 25
        break_length = 5

        [[block]]
        block = "time"
        interval = 60
        format =  "  %a %h %d  %I:%M  "
      '';

      xsession.scriptPath = ".hm-xsession";
      xsession.windowManager.i3 = {
        enable = true;
        config = {
          modifier = mod;
          keybindings = lib.mkOptionDefault rec {
            "${mod}+h" = "focus left";
            "${mod}+j" = "focus down";
            "${mod}+k" = "focus up";
            "${mod}+l" = "focus right";
            "${mod}+semicolon" = "focus parent";

            "${mod}+Shift+h" = "move left";
            "${mod}+Shift+j" = "move down";
            "${mod}+Shift+k" = "move up";
            "${mod}+Shift+l" = "move right";

            "${mod}+Shift+x" = "kill";

            "${mod}+Return" = "exec alacritty";

            "${mod}+Shift+s" = "split h";
            "${mod}+Shift+v" = "split v";

            "${mod}+f" = "fullscreen";

            "${mod}+Shift+r" = "restart";

            "${mod}+r" = "mode resize";

            # Marks
            "${mod}+Shift+m" = ''exec i3-input -F "mark %s" -l 1 -P 'Mark: ' '';
            "${mod}+m" = ''exec i3-input -F '[con_mark="%s"] focus' -l 1 -P 'Go to: ' '';

            # Screenshots
            "${mod}+q" = "exec \"maim | xclip -selection clipboard -t image/png\"";
            "${mod}+Shift+q" = "exec \"maim -s | xclip -selection clipboard -t image/png\"";
            "${mod}+Ctrl+q" = "exec ${pkgs.writeShellScript "peek.sh" ''
            picom &
            picom_pid=$!
            peek || true
            kill -SIGINT $picom_pid
            ''}";

            # Launching applications
            "${mod}+u" = "exec ${pkgs.writeShellScript "rofi" ''
              rofi \
                -modi 'combi' \
                -combi-modi "window,drun,ssh,run" \
                -font '${decorationFont}' \
                -show combi
            ''}";

            # Passwords
            "${mod}+p" = "exec rofi-pass -font '${decorationFont}'";

            # Media
            "XF86AudioPlay" = "exec playerctl play-pause";
            "XF86AudioNext" = "exec playerctl next";
            "XF86AudioPrev" = "exec playerctl previous";
            "XF86AudioRaiseVolume" = "exec pulseaudio-ctl up";
            "XF86AudioLowerVolume" = "exec pulseaudio-ctl down";
            "XF86AudioMute" = "exec pulseaudio-ctl mute";

            # Lock
            Pause = "exec \"sh -c 'playerctl pause; ${pkgs.i3lock}/bin/i3lock -c 222222'\"";
            F7 = Pause;

            # Screen Layout
            "${mod}+Shift+t" = "exec xrandr --auto";
            "${mod}+t" = "exec ${screenlayout.home}";
            "${mod}+Ctrl+t" = "exec ${pkgs.writeShellScript "fix_term.sh" ''
              xrandr --output eDP-1 --off && ${screenlayout.home}
            ''}";

            # Notifications
            "${mod}+Shift+n" = "exec killall -SIGUSR1 .dunst-wrapped";
            "${mod}+n" = "exec killall -SIGUSR2 .dunst-wrapped";
          };

          fonts = [ decorationFont ];

          colors = with solarized; rec {
            focused = {
              border = base01;
              background = base01;
              text = base3;
              indicator = red;
              childBorder = base02;
            };
            focusedInactive = focused // {
              border = base03;
              background = base03;
              # text = base1;
            };
            unfocused = focusedInactive;
            background = base03;
          };

          modes.resize = {
            l = "resize shrink width 5 px or 5 ppt";
            k = "resize grow height 5 px or 5 ppt";
            j = "resize shrink height 5 px or 5 ppt";
            h = "resize grow width 5 px or 5 ppt";

            Return = "mode \"default\"";
          };

          bars = [{
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs --never-pause ~/.config/i3status.toml";
            fonts = [ decorationFont iconFont ];
            position = "top";
            colors = with solarized; rec {
              background = base03;
              statusline = base3;
              separator = base1;
              activeWorkspace = {
                border = base03;
                background = base1;
                text = base3;
              };
              focusedWorkspace = activeWorkspace;
              inactiveWorkspace = activeWorkspace // {
                background = base01;
              };
              urgentWorkspace = activeWorkspace // {
                background = red;
              };
            };
          }];
        };
      };

      services.dunst = {
        enable = true;
        settings = with solarized; {
          global = {
            font = "MesloLGSDZ ${toString (config.system.machine.i3FontSize * 1.5)}";
            allow_markup = true;
            format = "<b>%s</b>\n%b";
            sort = true;
            alignment = "left";
            geometry = "600x15-40+40";
            idle_threshold = 120;
            separator_color = "frame";
            separator_height = 1;
            word_wrap = true;
            padding = 8;
            horizontal_padding = 8;
          };

          frame = {
            width = 0;
            color = "#aaaaaa";
          };

          shortcuts = {
            close = "ctrl+space";
            close_all = "ctrl+shift+space";
            history = "ctrl+grave";
            context = "ctrl+shift+period";
          };

          urgency_low = {
            background = base03;
            foreground = base3;
            timeout = 5;
          };

          urgency_normal = {
            background = base02;
            foreground = base3;
            timeout = 7;
          };

          urgency_critical = {
            background = red;
            foreground = base3;
            timeout = 0;
          };
        };
      };

      gtk = {
        enable = true;
        iconTheme.name = "Adwaita";
        theme.name = "Adwaita";
      };
  };
}
