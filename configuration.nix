# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
    imports =
        [
        # Include the results of the hardware scan.
            ./hardware-configuration.nix
            ./luks.nix
            ./users.nix
            ./pkgs.nix
            ./programs.nix
            ./services/libvirt.nix
            ./services/mopidy.nix
            ./services/smb.nix
            ./services/sshd.nix
            ./networking/firewall.nix
        ];

    boot = {
        # Use the gummiboot efi boot loader.
        vesa = false;

        loader = {
            gummiboot.enable = true;
            gummiboot.timeout = 1;
            efi.canTouchEfiVariables = true;
        };

        kernel.sysctl = {
            # vm memory assignment
            "vm.nr_overcommit_hugepages" = 2050;
            "vm.hugetlb_shm_group" = 8;

            "kernel.dmesg_restrict" = 1;
        };

        tmpOnTmpfs = true;

        kernelModules = [
            "kvm-intel"
            "vfio_pci"
            "vfio_iommu_type1"
            "vhost" "vhost_net" "vhost_scsi"
            "zram"
            "coretemp"
            "nct6775"
            ];

        kernelParams = [ #"video=efifb"
            "iommu=pt"
            "intel_iommu=on,igfx_off"
            "i915.modeset=1"
            "vfio_pci.ids=1002:6818,1002:aab0"
            "vfio_pci.disable_vga=1"
            "libahci.ignore_sss=1"
            "zfs.zfs_arc_max=2147483648"
            #"libata.force=1.00:noncq"             # NCQ on Samsung is broken (suprise!)
            "hugepagesz=1GB"
            "hugepages=8"
        ];

        extraModprobeConfig = ''
            options loop                max_loop=16
            options zram                num_devices=8

            options kvm                 ignore_msrs=1
            options kvm_intel           enable_apicv=1
            options kvm_intel           ept=1
            options kvm_intel           emulate_invalid_guest_state=0
            options vfio_iommu_type1    allow_unsafe_interrupts=0

            softdep radeon              pre: vfio-pci
            options vfio_pci            ids=1002:6818,1002:aab0
            options vfio_pci            disable_vga=1

            options i915 fastboot=0
            options i915 enable_rc6=7
            options i915 semaphores=1

            options radeon              gartsize=-1
            options radeon              audio=0

            options processor           ignore_ppc=1

            options snd-hda-intel       beep_mode=0
            options snd-hda-intel       enable_msi=1
            options snd-hda-intel       power_save=30
            options snd-hda-intel       power_save_controller=1

            options usbcore             autosuspend=30

            options libata              ignore_hpa=0
            options libata              allow_tpm=0
            options libahci             skip_host_reset=1
            options libahci             ignore_sss=1
            options libahci             devslp_idle_timeout=300

            options zfs                 zfs_arc_max=2147483648
            options zfs                 zfs_prefetch_disable=1
            options zfs                 zfs_txg_timeout=30
            options zfs                 zfs_vdev_scheduler=bfq

            options zfs                 zfs_top_maxinflight=600
            options zfs                 zfs_scrub_delay=0
            options zfs                 zfs_resilver_delay=0
            options zfs                 zfs_scan_idle=10
            options zfs                 zfs_scan_min_time_ms=5000
            '';


        initrd.checkJournalingFS = true;
        initrd.kernelModules = [ "fbcon" "i915" "loop" "vfio-pci"];
        initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "dm_thin_pool" ];
        initrd.supportedFilesystems = [ "zfs" "ext4" ];
        supportedFilesystems = [ "zfs" "ext4" ];
        zfs.extraPools = [ "zstorage" ];

        blacklistedKernelModules = [
            "radeon" "pcspkr" "wl"
                "b43" "b43legacy" "ssb" "bcm43xx"
                "brcm80211" "brcmfmac" "brcmsmac" "bcma"
        ];
    };

    fileSystems = {
        "/" = {
            options = "i_version,nodiscard,noatime,delalloc,journal_checksum,commit=30";
            #options = "i_version,noatime,delalloc,journal_checksum,journal_async_commit,commit=30";
        };
        "/var/home" = {
            options = "nodiscard,noatime";
        #    options = "nodiscard,noatime,journal_async_commit";
        };
        "/boot" = {
            options = "noatime,noauto,x-systemd.automount";
        };
    };

    systemd.mounts = [
        # disable mounting hugepages by systemd,
        # it doesn't know about 1G pagesize
        { where = "/dev/hugepages";
            enable = false;
        }
        { where = "/dev/hugepages/hugepages-2048kB";
            enable  = true;
            what  = "hugetlbfs";
            type  = "hugetlbfs";
            options = "pagesize=2M";
            requiredBy  = ["basic.target"];
        }
        { where = "/dev/hugepages/hugepages-1048576kB";
            enable  = true;
            what  = "hugetlbfs";
            type  = "hugetlbfs";
            options = "pagesize=1G";
            requiredBy  = ["basic.target"];
        }
        { where = "/proc";
            enable = true;
            what = "proc";
            type = "proc";
            options = "hidepid=2";
            unitConfig = {
                DefaultDependencies = "no";
            };
        }
    ];

    # do fstrim every week, instead of discard-on-delete
    systemd.services.fstrim = {
        description = "Discard unused blocks";
        path = [ pkgs.utillinux ];
        #enable = false; # user timer for this instead
        serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.utillinux}/bin/fstrim -av";
        };
    };

    systemd.timers.fstrim = {
        description = "Discard unused blocks once a week";
        timerConfig = {
            OnCalendar = "weekly";
            AccuracySec = "1h";
            Unit = "fstrim.service";
            Persistent = true;
        };
        wantedBy = ["timers.target"];
    };

    services.journald.extraConfig = ''
        Compress=yes
        SystemMaxUse=1024M
        SystemMaxFileSize=8M
    '';

    swapDevices = [ ];

    hardware.cpu.intel.updateMicrocode = true;

    services.udev.extraRules = ''
        # force disks stanby after 15 minutes
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -S 180 /dev/%k"

        # default schedulers
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/fifo_batch}="16"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/writes_starved}="8"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"

        # fancy swap-on-zram rule
        ACTION=="add", KERNEL=="zram[0-9]", ATTR{comp_algorithm}="lzo", ATTR{disksize}="256M"
        ACTION=="add", KERNEL=="zram[0-9]", RUN+="${pkgs.busybox}/bin/mkswap /dev/%k"
        ACTION=="add", KERNEL=="zram[0-9]", RUN+="${pkgs.busybox}/bin/swapon -p1 /dev/%k"

        KERNEL=="zram[0-9]", SUBSYSTEM=="block", ENV{UDISKS_IGNORE}="1"
    '';

    networking.hostName = "KATAMARI";
    networking.hostId = "6e003f24";
    networking.wireless.enable = false;
    networking.networkmanager.enable = true;

    security.rtkit.enable = true;
    security.pam.loginLimits = [
        {
            domain = "@libvirtd";
            type = "-";
            item = "rtprio";
            value = "99";
        }
        {
            domain = "@libvirtd";
            type = "-";
            item = "nice";
            value = "-20";
        }
        {
            domain = "@libvirtd";
            type = "-";
            item = "memlock";
            value = "unlimited";
        }
    ];

    system.stateVersion = "15.09";

    i18n = { # Select internationalisation properties and timezone
        consoleFont = "lat2-16";
        consoleKeyMap = "pl";
        defaultLocale = "en_US.UTF-8";
    };

    time.timeZone = "Europe/Warsaw";

    nix.extraOptions = ''
        build-cores = 0

        binary-caches-parallel-connections = 4

        gc-keep-outputs = true
        gc-keep-derivations = true

        auto-optimise-store = true
    '';

}
