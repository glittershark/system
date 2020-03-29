{ config, lib, pkgs, ... }:

{
  imports =
    [
      ./xserver.nix
      ./emacs.nix
      ./sound.nix
      ./urbint.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  time.timeZone = "America/New_York";

  environment.systemPackages = with pkgs; [
    wget
    vim
    zsh
    git
    w3m
    libnotify
    file
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  #   pinentryFlavor = "gnome3";
  # };

  programs.nm-applet.enable = true;


  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  users.mutableUsers = true;
  programs.zsh.enable = true;
  environment.pathsToLink = [ "/share/zsh" ];
  users.users.grfn = {
    isNormalUser = true;
    initialPassword = "password";
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "docker"
    ];
    shell = pkgs.zsh;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.03"; # Did you read the comment?

  nixpkgs.config.allowUnfree = true;

  fonts.fonts = with pkgs; [
    nerdfonts
  ];

  services.geoclue2.enable = true;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
    powertop.enable = true;
  };
  # Hibernate on low battery
  laptop.onLowBattery = {
    enable = true;
    action = "hibernate";
    thresholdPercentage = 5;
  };

  nix = {
    autoOptimiseStore = true;
  };
}
