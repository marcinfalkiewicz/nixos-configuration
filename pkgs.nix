# vim: ft=nix

{ config, pkgs, ... }:

{

    environment.etc."sensors.conf" = {
        source = "/etc/nixos/kernel/sensors";
        enable = true;
    };

    environment.shellAliases = {
        sensors = "${pkgs.lm_sensors}/bin/sensors -c /etc/sensors.conf";
    };

    nixpkgs.config = {
        allowUnfree = true;
        withGnome = false;

        firefox = {
            enableGoogleTalkPlugin = false;
            enableAdobeFlash = true;
            jre = false;
        };

        packageOverrides = pkgs: {
            linux_custom = pkgs.linux_custom.override {
                kernelPatches = [
                { patch = "./kernel/patches/0001-block-cgroups-kconfig-build-bits-for-BFQ-v7r8-4.1.patch"; name = "01-block-bfq"; }
                { patch = "./kernel/patches/0002-block-introduce-the-BFQ-v7r8-I-O-sched-for-4.1.patch"; name = "02-block-bfq"; }
                { patch = "./kernel/patches/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-v7r8-for-4.1.0.patch"; name = "03-block-bfq"; }
                { patch = "./kernel/patches/0004-enable_additional_cpu_optimizations.patch"; name = "04-cpu-optimizations"; }
                { patch = "./kernel/patches/0005-Revert-x86-efi-Fix-multiple-GOP-device-support.patch"; name = "05-revert-multiple-efi-gop-support"; }
                { patch = "./kernel/patches/0006-Revert-iommu-vt-d-fix-range-computation-when-making-.patch"; name = "06-revert-iommu-fix-range-computation"; }
                ];

                extraConfig = "
                    MNATIVE y

                #    PREEMPT y
                #    PREEMPT_RCU y
                #    SCHED_AUTOGROUP y

                #    ZRAM_LZ4_COMPRESS y

                    IOSCHED_BFQ y
                    DEFAULT_BFQ y

                #    VFIO_PCI_VGA y

                ";
            };
        };

    };

    #kernelPackages = pkgs.linuxPackages_4_1;
    boot.kernelPackages = pkgs.linuxPackages_custom {
        version = "4.1.15";
        src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v4.x/linux-4.1.15.tar.xz";
            sha256 = "18sr0dl5ax6pcx6nqp9drb4l6a38g07vxihiqpbwb231jv68h8j7";
        };
        configfile = /etc/nixos/kernel/config;
    };

    environment.systemPackages = with pkgs; [
        pkgs.firefoxWrapper
            thunderbird

            ncmpcpp

            mpv
            spotify
            pavucontrol
            virtmanager

            ffmpeg
            gst_ffmpeg
            gst_plugins_base
            gst_plugins_bad
            gst_plugins_good
            gst_plugins_ugly

            openvpn
            gnupg
            x11vnc

            gtk_engines
            gtk-engine-murrine

            lm_sensors
            smartmontools
            gptfdisk
            multipath_tools
            thin-provisioning-tools
            hdparm
            iotop
            iftop
            htop
            ntfs3g

            pciutils
            usbutils

            curl
            tmux
            vim
            git
            qemu
            OVMF
            mosh
            cryptsetup
            samba

            zip
            xz
            lzop

            python27

            haskellPackages.xmobar

            xorg.xset
            xorg.xrdb
            xorg.xmodmap
            xorg.xrandr
            ];

    services.printing.enable = false;

    services.xserver = {
        autorun = true;
        enable = true;
        layout = "pl";
        #xkbOptions = "eurosign:e";

        videoDriver = "intel";
        vaapiDrivers = [ pkgs.vaapiIntel ];
        deviceSection = ''
            BusID   "PCI:0:2:0"
            Option "TearFree" "true"
            '';
    };

    services.xserver.displayManager.lightdm.enable = true;

    services.xserver.desktopManager.gnome3.enable = false;
    services.xserver.desktopManager.gnome3.sessionPath = [];

    #services.gnome3 = {
    #    gvfs.enable = true;
    #    seahorse.enable = true;
    #    tracker.enable = true;
    #    gnome-keyring.enable = true;
    #    sushi.enable = true;
    #};

    #environment.gnome3.packageSet = pkgs.gnome3_16;
    #environment.gnome3.excludePackages = with pkgs.gnome3; [
    #    gnome-photos
    #        gnome-clocks
    #        gnome-music
    #        #gnome-user-docs
    #        gnome-documents
    #        vino
    #        epiphany
    #        gucharmap
    #        totem
    #        bijiben
    #        evolution
    #];

    services.xserver.desktopManager.xterm.enable = false;

    services.xserver.windowManager.xmonad.enable = true;

    #services.xserver.windowManager.default = "xmonad";
    services.xserver.windowManager.xmonad.extraPackages = haskellPackages:
        [
            haskellPackages.xmonad-contrib
            haskellPackages.xmonad-extras
        ];

    services.haveged = {
        enable = true;
    };

    hardware.opengl = {
        driSupport32Bit = true;
        s3tcSupport = true;
    };

    hardware.pulseaudio.support32Bit = true;
    hardware.pulseaudio.enable = true;

}
