# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
    imports =
        [ # Include the results of the hardware scan.
            ./hardware-configuration.nix
            ./users.nix
            ./pkgs.nix
            ./programs.nix
        ];

    boot = { # Use the gummiboot efi boot loader.
        vesa = false;

        loader = {
            gummiboot.enable = true;
            gummiboot.timeout = 1;
            efi.canTouchEfiVariables = true;
        };

        kernel.sysctl = { # vm memory assignment
            "vm.nr_overcommit_hugepages" = 7700;
            "vm.hugetlb_shm_group" = 8;

            "kernel.dmesg_restrict" = 1;
        };

        kernelPackages = pkgs.linuxPackages_4_0;
#kernelPackages = pkgs.linuxPackages_custom {
#    version = "3.19.0-HYDRA";
#    src = pkgs.fetchurl {
#        url = "mirror://kernel/linux/kernel/v3.x/linux-3.19.tar.xz";
#        sha256 = "be42511fe5321012bb4a2009167ce56a9e5fe362b4af43e8c371b3666859806c";
#    };
#    configfile = /etc/nixos/kernel.config;
#};

#extraModulePackages = [ "" ];
        kernelModules = [ "kvm-intel" "vfio-pci" "vhost" "vhost_net" "vhost_scsi" "zram" ];
        kernelParams = [ #"video=efifb"
            "iommu=pt"
            "intel_iommu=on,igfx_off"
            "vfio-pci.ids=1002:6818,1002:aab0"
            "libata.force=1.00:noncq"             # NCQ on Samsung is broken (suprise!)
        ];

        extraModprobeConfig = ''
            options loop                max_loop=16
            options zram                num_devices=8

            options kvm                 ignore_msrs=1
            options kvm_intel           enable_apicv=1
            options kvm_intel           ept=1
            options kvm_intel           emulate_invalid_guest_state=0
            options vfio_iommu_type1    allow_unsafe_interrupts=0

            softdep radeon pre: vfio-pci
            options vfio-pci            ids=1002:6818,1002:aab0

            options i915 fastboot=0
            options i915 enable_rc6=7
            options i915 semaphores=1

            options radeon              gartsize=-1
            options radeon              audio=0

            options processor           ignore_ppc=1

            options snd-hda-intel   beep_mode=0
            options snd-hda-intel   enable_msi=1
            options snd-hda-intel   power_save=30
            options snd-hda-intel   power_save_controller=1

            options usbcore         autosuspend=30

            options libata          ignore_hpa=0
            options libata          allow_tpm=0
            options libahci         skip_host_reset=1
            options libahci         ignore_sss=1
            options libahci         devslp_idle_timeout=300

            options zfs             zfs_arc_max=4294967296

            options zfs             zfs_prefetch_disable=1

            options zfs             zfs_txg_timeout=10

            options zfs             zfs_vdev_max_pending=1
            options zfs             zfs_vdev_scheduler=bfq

            options zfs             zfs_top_maxinflight=600
            options zfs             zfs_scrub_delay=0
            options zfs             zfs_resilver_delay=0
            options zfs             zfs_scan_idle=10
            options zfs             zfs_scan_min_time_ms=5000
            '';


        initrd.kernelModules = [ "fbcon" "i915" "loop" "vfio-pci"];
        initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage"];
        initrd.supportedFilesystems = [ "btrfs" "f2fs" "zfs" ];
        blacklistedKernelModules = [
            "radeon" "pcspkr" "wl"
            "b43" "b43legacy" "ssb" "bcm43xx"
            "brcm80211" "brcmfmac" "brcmsmac" "bcma"
        ];

## old hack for luks with detached header
#initrd.extraUtilsCommands = ''
#    mkdir -p $out/luks
#    cp -pdv /etc/nixos/luks/luks-nopedisk.header $out/luks/luks-ident.header
#    cp -pdv /etc/nixos/luks/luks-nopedisk.keyfile $out/luks/luks-ident.keyfile
#'';

#initrd.luks.cryptoModules = [ "plain" "serpent" "serpent_avx2" "xts" "sha256" "sha512" ];

#initrd.luks.devices = [
#  { name = "luks-nopedisk";
#    device = "/dev/disk/by-id/nopedisk";
#    header = "$PATH/../luks/luks-nopedisk.header";
#    keyFile = "$PATH/../luks/luks-nopedisk.keyfile";
#  }
#];

#initrd.luks.cryptoModules = [ "serpent_avx2" "xts" "sha512" ];
#initrd.luks.devices = [
#  { name = "rootfs";
#    device = "/dev/sda1";
#    allowDiscards = true;
#  }
#];
    };

    fileSystems = {
        "/" = {
            options = "noatime,background_gc=on,discard";
        };

        "/boot" = {
            device = "/dev/sda1";
            fsType = "vfat";
            options = "noatime,noauto,x-systemd.automount";
        };

## storage zpool
#
# zfs requires noauto,x-systemd.automount along with mountpoint=legacy
#   otherwise breaks mount service at boot (importing too slow)

        "/var/home/" = {
            device = "storage/home";
            fsType = "zfs";
            options = "noatime,noxattr,noauto,x-systemd.automount";
        };
    };

#zramSwap = {
#  enable = true;
#  memoryPercent = 12;
#  numDevices = 8;
#};

    swapDevices = [ ];

    hardware.cpu.intel.updateMicrocode = false;

    networking.hostName = "KATAMARI";
    networking.hostId = "3964c893";
    networking.wireless.enable = false;
    networking.networkmanager.enable = true;

    i18n = { # Select internationalisation properties and timezone
        consoleFont = "lat2-16";
        consoleKeyMap = "pl";
        defaultLocale = "en_US.UTF-8";
    };

    time.timeZone = "Europe/Warsaw";

    nix.extraOptions = ''
        build-cores = 0

        gc-keep-outputs = true
        gc-keep-derivations = true

        auto-optimise-store = true
        '';

}
