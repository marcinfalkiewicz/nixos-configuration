
{ config, pkgs, ... }:

let

  kernel_4_9 = {
    configfile = /etc/nixos/kernel/config-4.9;
    patches = [
      pkgs.kernelPatches.bridge_stp_helper
      { patch = /etc/nixos/kernel/patches/4.9/0001-block-cgroups-kconfig-build-bits-for-BFQ-v7r11-4.5.0.patch;
        name = "block-bfq-0001"; }
      { patch = /etc/nixos/kernel/patches/4.9/0002-block-introduce-the-BFQ-v7r11-I-O-sched-for-4.5.0.patch;
        name = "block-bfq-0002"; }
      { patch = /etc/nixos/kernel/patches/4.9/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-v7r11-for.patch;
        name = "block-bfq-0003"; }
      { patch = /etc/nixos/kernel/patches/4.9/0004-Turn-into-BFQ-v8r7-for-4.9.0.patch;
        name = "block-bfq-0004"; }
      { patch = /etc/nixos/kernel/patches/1000-enable_additional_cpu_optimizations.patch;
        name = "cpu-optimizations"; }
    ];
  };
  
  kernel_4_12 = {
    configfile = /etc/nixos/kernel/config-4.12;
    patches = [
      pkgs.kernelPatches.bridge_stp_helper
      { patch = /etc/nixos/kernel/patches/1000-enable_additional_cpu_optimizations.patch;
        name = "cpu-optimizations"; }
    ];
  };

  kernel = kernel_4_12;

in
{

  environment.etc."sensors.conf" = {
    source = "/etc/nixos/kernel/sensors";
    enable = true;
  };

  environment.interactiveShellInit = ''
    # A nix query helper function
    nix-rebuild()
    {
       nix-env -f '<nixpkgs>' -i 'all'
    }
    nix-search()
    {
      case "$@" in
        -h|--help|"")
          printf "nq: A tiny nix-env wrapper to search for packages in package name, attribute name and description fields\n";
          printf "\nUsage: nq <case insensitive regexp>\n";
          return
          ;;
      esac
      nix-env -f '<nixpkgs>' -qaP --description \* | grep -i "$@"
    }

    drop_caches()
    {
      sync
      echo $1 | sudo tee /proc/sys/vm/drop_caches
      sync
    }

    sensors()
    {
      ${pkgs.lm_sensors}/bin/sensors -c /etc/sensors.conf $@
    }

    mount_udisks()
    {
      case "$@" in
        -h|--help|"")
          udisksctl mount -h
          return
          ;;
      esac
      udisksctl mount -b "$@"
    }

    umount_udisks()
    {
      case "$@" in
        -h|--help|"")
          udisksctl unmount -h
          return
          ;;
      esac
      udisksctl unmount -b "$@"
    }

    export HISTCONTROL=ignoreboth   # ignorespace + ignoredups
  '';

  nixpkgs.config = {
    allowUnfree = true;
    withGnome = false;

    #firefox = {
    #  enableGoogleTalkPlugin = false;
    #  enableAdobeFlash = true;
    #  jre = false;
    #};

    mpv = {
      vaapiSupport = true;
      bluraySupport = false;
      dvdnavSupport = false;
      dvdreadSupport = false;
      vdpauSupport = false;
    };

    packageOverrides = pkgs: rec {
      qemu_kvm = pkgs.qemu.override {
        x86Only = true;
      };

      linux_node = pkgs.buildLinux rec {
        #inherit (pkgs.linux_4_12) version src;
        version = "4.12.3";

        src = pkgs.fetchurl {
          url = "mirror://kernel/linux/kernel/v4.x/linux-4.12.3.tar.xz";
          sha256 = "05mz5rza2cn7pnn0cgd4pxal4xyjk74bl6h742v0xxlf4aqrvgcr";
        };

        configfile = /etc/nixos/kernel/config-4.12;
        kernelPatches = [
          #pkgs.kernelPatches.bridge_stp_helper
          { patch = /etc/nixos/kernel/patches/1000-enable_additional_cpu_optimizations.patch;
            name = "cpu-optimizations"; }
        ];

        allowImportFromDerivation = true;
      };
      linuxPackages_node = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_node);
      linuxPackages = linuxPackages_node;

    };
  };

  boot.kernelPackages = pkgs.linuxPackages_node;

  environment.systemPackages = with pkgs; [
    #config.boot.kernelPackages.perf
    #config.boot.kernelPackages.sysdig
    #config.boot.kernelPackages.systemtap

    lm_sensors
    smartmontools
    hddtemp
    efibootmgr
    gptfdisk
    multipath_tools
    thin-provisioning-tools
    hdparm
    iotop
    iftop
    htop
    ntfs3g
    nix-prefetch-scripts

    pciutils
    usbutils

    curl
    tmux
    vim
    git
    mosh
    cryptsetup
    samba

    audit
    which
    psmisc

    ethtool
    bridge-utils

    zip
    xz
    lzop

    python27
    libxml2 # for xmllint

    x11vnc
    mpv
    haskellPackages.xmobar
  ]
  ++ stdenv.lib.optionals config.services.xserver.desktopManager.plasma5.enable [
    #kdeconnect
    kdeApplications.dolphin
    kdeApplications.dolphin-plugins
    kdeApplications.kate
    kdeApplications.ark
    kdeApplications.kwalletmanager
    kdeApplications.gwenview
    kdeApplications.okular
    kdeApplications.kcalc
    kdeApplications.filelight
  ];

  fonts = {
    fonts = [
      pkgs.cantarell_fonts
      pkgs.corefonts
      pkgs.freefont_ttf
      pkgs.dejavu_fonts
      pkgs.liberation_ttf
      pkgs.opensans-ttf
      pkgs.roboto
      pkgs.oxygenfonts
    ];
    fontconfig.ultimate = {
      enable = true;
    };
  };

  services.printing.enable = false;
  services.xserver = {
    autorun = true;
    enable = true;
    layout = "pl";
    libinput.enable = true;
    #xkbOptions = "eurosign:e";
    xkbOptions = "shift:both_capslock, ctrl:nocaps, terminate:ctrl_alt_bksp";

    videoDrivers = [ "amdgpu" "modesetting" ];
    deviceSection = ''
      BusID  "PCI:1:0:0"
      Option "DRI" "3"
      #Option "TearFree" "true"
    '';
  };

  services.xserver.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    autoLogin = { enable = true; user = "dweller"; };
  };
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.desktopManager.xterm.enable = false;
  services.xserver.windowManager.xmonad.enable = true;

  services.xserver.windowManager.xmonad.extraPackages = haskellPackages:
    [
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad-extras
      haskellPackages.xmobar
    ];

  hardware.opengl = {
    extraPackages = [ pkgs.vaapiIntel pkgs.vaapiVdpau ];
    driSupport32Bit = true;
    s3tcSupport = true;
  };

  hardware.pulseaudio.support32Bit = true;
  hardware.pulseaudio.enable = true;

}
