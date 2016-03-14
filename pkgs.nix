# vim: ft=nix

{ config, pkgs, ... }:

let

kver = "4.4.5";

#khash = "084ij19vgm27ljrjabqqmlqn27p168nsm9grhr6rajid4n79h6ab"; # 4.1.17
#khash = "0mwaqvl7dkasidciah1al57a1djnsk46ha5mjy4psq2inj71klky"; # 4.4.1
#khash = "09l6y0nb8yv7l16arfwhy4i5h9pkxcbd7hlbw0015n7gm4i2mzc2"; # 4.4.2
#khash = "1pcichd5hp3hzb3hwh5737jwqmfv4ylhw04sbby3hzmxkfqrqdqb"; # 4.4.3
#khash = "0b4190mwmxf329n16yl32my7dfi02pi7qf39a8v61sl9b2gxffad"; # 4.4.4
khash = "1daavrj2msl85aijh1izfm1cwf14c7mi75hldzidr1h2v629l89h"; # 4.4.5

in
{

    environment.etc."sensors.conf" = {
        source = "/etc/nixos/kernel/sensors";
        enable = true;
    };

    environment.interactiveShellInit = ''
        # A nix query helper function
        nix-search()
        {
            case "$@" in
                -h|--help|"")
                    printf "nq: A tiny nix-env wrapper to search for packages in package name, attribute name and description fields\n";
                    printf "\nUsage: nq <case insensitive regexp>\n";
                    return
                    ;;
            esac
            nix-env -qaP --description \* | grep -i "$@"
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

        export HISTCONTROL=ignoreboth   # ignorespace + ignoredups
    '';

    nixpkgs.config = {
        allowUnfree = true;
        withGnome = false;

        firefox = {
            enableGoogleTalkPlugin = false;
            enableAdobeFlash = true;
            jre = false;
        };

        mpv = {
            vaapiSupport = true;
            bluraySupport = false;
            dvdnavSupport = false;
            dvdreadSupport = false;
            vdpauSupport = false;
        };

        packageOverrides = pkgs: rec {
            qemu = pkgs.qemu.override {
                x86Only = true;
            };
            libvirt = pkgs.libvirt.override {
                xen = null;
            };
            libvirt-glib = pkgs.libvirt-glib.override {
                xen = null;
            };
            linuxPackages_katamari = pkgs.recurseIntoAttrs (
                pkgs.linuxPackagesFor (
                    pkgs.buildLinux rec {
                        version = "${kver}";
                        src = pkgs.fetchurl {
                            url = "mirror://kernel/linux/kernel/v4.x/linux-${kver}.tar.xz";
                            sha256 = "${khash}";
                        };

                        configfile = /etc/nixos/kernel/config_4.4;
                        kernelPatches = [
                            { patch = /etc/nixos/kernel/patches/4.4.x/0001-block-cgroups-kconfig-build-bits-for-BFQ-v7r11-4.4.0.patch;
                              name = "block-bfq-0001"; }
                            { patch = /etc/nixos/kernel/patches/4.4.x/0002-block-introduce-the-BFQ-v7r11-I-O-sched-for-4.4.0.patch;
                              name = "block-bfq-0002"; }
                            { patch = /etc/nixos/kernel/patches/4.4.x/0003-block-bfq-add-Early-Queue-Merge-EQM-to-BFQ-v7r11-for.patch;
                              name = "block-bfq-0003"; }
                            { patch = /etc/nixos/kernel/patches/4.4.x/0004-enable_additional_cpu_optimizations.patch;
                              name = "cpu-optimizations"; }
                            { patch = /etc/nixos/kernel/patches/4.4.x/0005-Revert-x86-efi-Fix-multiple-GOP-device-support.patch;
                              name = "revert-multiple-efi-gop-support"; }
                            #{ patch = /etc/nixos/kernel/patches/4.4.x/grsecurity-3.1-4.4.4-201603032158.patch;
                            #  name = "grsecurity"; }
                        ];

                        allowImportFromDerivation = true;
                    }) linuxPackages_katamari
            );

        };
    };

    boot.kernelPackages = pkgs.linuxPackages_katamari;

    environment.systemPackages = with pkgs; [
        pkgs.firefoxWrapper
        thunderbird

        ncmpcpp

        mpv
        spotify
        pavucontrol

        virtmanager
        qemu
        OVMF

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
        efibootmgr
        gptfdisk
        multipath_tools
        thin_provisioning_tools
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

        zip
        xz
        lzop

        python27
        libxml2 # for xmllint

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
        xkbOptions = "shift:both_capslock, ctrl:nocaps, terminate:ctrl_alt_bksp";

        videoDriver = "intel";
        vaapiDrivers = [ pkgs.vaapiIntel ];
        deviceSection = ''
            BusID  "PCI:0:2:0"
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

    hardware.opengl = {
        driSupport32Bit = true;
        s3tcSupport = true;
    };

    hardware.pulseaudio.support32Bit = true;
    hardware.pulseaudio.enable = true;

}
