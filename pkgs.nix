
{ config, pkgs, ... }:

{

  nixpkgs.config = {
    allowUnfree = true;
    withGnome = true;

    firefox = {
      enableGoogleTalkPlugin = false;
      enableAdobeFlash = true;
      jre = false;
    };

  };


  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    pkgs.firefoxWrapper
    thunderbird
    virtmanager

    spotify
    #mopidy
    #mopidy-mopify
    #mopidy-spotify
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

    smartmontools
    gptfdisk
    iotop
    iftop
    htop

    # misc
    curl
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

    python27
  ];

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

  services.gnome3 = {
      gvfs.enable = true;
      seahorse.enable = true;
      tracker.enable = true;
      gnome-keyring.enable = true;
      sushi.enable = true;
  };

  services.mopidy = {
      enable = false;
      extensionPackages = [
          pkgs.mopidy-spotify
          pkgs.mopidy-mopify
      ];
  };

  services.openssh = {
      enable = true;
      ports = [ 2538 ];
      listenAddresses = [ { addr = "0.0.0.0"; port = 2538; } ];
      permitRootLogin = "no";
      forwardX11 = true;
  };

  services.haveged = {
      enable = true;
  };

  virtualisation.libvirtd = {
    enable = true;
    enableKVM = true;
  };

}
