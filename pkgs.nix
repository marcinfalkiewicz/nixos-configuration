{ config, pkgs, ... }:

{

  nixpkgs.config = {
    allowUnfree = true;

    firefox = {
      enableGoogleTalkPlugin = false;
      enableAdobeFlash = true;
    };
  };

  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    pkgs.firefoxWrapper
    thunderbird
    virtmanager

    spotify
    mopidy
    mopidy-mopify
    mopidy-spotify
    ncmpcpp

    mpv

    openvpn
    x11vnc

    # gtk3 -> gtk2 themes
    gtk_engines
    gtk-engine-murrine

    ffmpeg
    gst_ffmpeg
    gst_plugins_base
    gst_plugins_bad
    gst_plugins_good
    gst_plugins_ugly

    # gnome utilities
    gnome3.gnome-disk-utility
    gnome3.networkmanagerapplet
    gnome3.networkmanager_openvpn

    # misc
    curl
    htop
    tmux
    vim
    git
    qemu
    openjre
    mosh
    cryptsetup

    zip
    xz
    lzop

    binutils
    gnumake
    prelink
    ncurses
    gcc
    python27
  ];

  services.mopidy = {
      enable = false;
      extensionPackages = [
          pkgs.mopidy-spotify
          pkgs.mopidy-mopify
      ];
  };

  services.printing.enable = false;

  services.xserver = {
    autorun = true;
    enable = true;
    layout = "pl";
    xkbOptions = "eurosign:e";

    videoDriver = "intel";
    vaapiDrivers = [ pkgs.vaapiIntel ];
    deviceSection = ''
        Option "TearFree" "true"
    '';
  };

  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome3.enable = true;
  services.xserver.desktopManager.gnome3.sessionPath = [];

  environment.gnome3.packageSet = pkgs.gnome3_12;
  environment.gnome3.excludePackages = with pkgs.gnome3; [
    gnome-photos
    gnome-clocks
    gnome-music
    #gnome-user-docs
    gnome-documents
    vino
    epiphany
    gucharmap
    totem
    bijiben
    evolution
  ];

  virtualisation.libvirtd = {
    enable = true;
    enableKVM = true;
  };

}
