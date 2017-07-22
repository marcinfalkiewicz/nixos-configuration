#
{ config, pkgs, ... }:

let

  hostname = "NODE";

in
{
    imports =
        [
        # Include the results of the hardware scan.
            ./hardware-configuration.nix
            ./luks.nix
            ./networking.nix
            ./users.nix
            ./pkgs.nix
            ./programs.nix
            ./services.nix
        ];

    boot = {
        # Use the gummiboot efi boot loader.
        vesa = false;

        loader = {
            timeout = 2;

            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };

        kernel.sysctl = {
            # vm memory assignment
            #"vm.nr_overcommit_hugepages" = 2050;
            #"vm.hugetlb_shm_group" = 8;

            "kernel.dmesg_restrict" = 1;
            #"kernel.kptr_restrict" = 1;
            "kernel.nmi_watchdog" = 0;

            "kernel.sched_rt_period_us" = 1000000;
            "kernel.sched_rt_runtime_us" = 900000;

            "vm.dirty_background_bytes" = 16777216;
            "vm.dirty_bytes" = 50331648;
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
            "clocksource=hpet"
            "iommu=pt"
            "intel_iommu=on,igfx_off"
            #"i915.modeset=1"
            #"vfio_pci.ids=1002:6818,1002:aab0"  # AMD HD7870
            #"vfio_pci.ids=1002:67df,1002:aaf0"  # AMD RX480
            #"vfio_pci.disable_vga=1"
            "libahci.ignore_sss=1"
            "zfs.zfs_arc_max=2147483648"
            #"libata.force=1.00:noncq"             # NCQ on Samsung is broken (surprise!)
            "hugepagesz=1GB"
            #"hugepages=10"
            #"hugepagesz=2MB"
            #"hugepages=5632"
            "isolcpus=4,5,6,7"
            "nohz_full=4,5,6,7"
            "rcu_nocbs=4,5,6,7"
            "scsi_mod.use_blk_mq=1"
        ];

        extraModprobeConfig = ''
            options loop                max_loop=16
            options zram                num_devices=4

            options kvm                 ignore_msrs=1
            options kvm                 kvmclock_periodic_sync=1
            options kvm_intel           enable_apicv=1
            options kvm_intel           ept=1
            options kvm_intel           fasteoi=1
            options kvm_intel           emulate_invalid_guest_state=0
            options vfio_iommu_type1    allow_unsafe_interrupts=0

            softdep radeon              pre: vfio-pci
            #options vfio_pci            ids=1002:6818,1002:aab0
            options vfio_pci            ids=1002:67df,1002:aaf0
            options vfio_pci            disable_vga=1

            options i915                fastboot=0
            options i915                enable_rc6=7
            options i915                semaphores=1

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
            options zfs                 zfs_prefetch_disable=0
            options zfs                 zfs_txg_timeout=30
            options zfs                 zfs_vdev_scheduler=noop

            options zfs                 zio_taskq_batch_pct=50

            options spl                 spl_taskq_thread_dynamic=0
            options spl                 spl_taskq_thread_sequential=8

            options zfs                 zfs_top_maxinflight=600
            options zfs                 zfs_scrub_delay=0
            options zfs                 zfs_resilver_delay=0
            options zfs                 zfs_scan_idle=10
            options zfs                 zfs_scan_min_time_ms=5000
        '';

        initrd = {
            checkJournalingFS = true;
            kernelModules = [ "fbcon" "loop" "vfio-pci" ];
            availableKernelModules = [ 
              "ehci_pci" "ahci" "usbhid" "usb_storage" 
              "dm_mod" "dm_crypt" "md_mod" "raid10" 
            ];
            supportedFilesystems = [ "ext4" "xfs" ];
            mdadmConf = "
DEVICE partitions
ARRAY /dev/md0 metadata=1.2 name=NODE:0 UUID=70c2f80c:4538004f:e9b15630:810e5f43
            ";
            #compressor = "xz -9 -e -T4";

            network = {
              enable = true;
              ssh = {
                enable = true;
                port = 2539;
                hostRSAKey = /etc/nixos/initrd/host_rsa_key;
                authorizedKeys = [
                  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeys81joKNKQQK5vDYxU9ar4V8qiTOERK5Guti/iFc2taS0wUCeijWdGqd3CT1hfzI3wzv0DAuvrOIqo+VEHgR4ejgkWvdsiHCefYGpNE5sTq79Nbiwnzn5hMEAlRvgN7lgh1KvHaSmgdHoy9BfqH4HZdnugIZ40ON446atX0kUl2fNDyLccCVXdni6lFm76pkJZw92PHbKmRtvMmBd9BYsuzRkCTbUtQRETvaYjY02ffHCRYq8U7B16EV6+/tkMwRuw4S3lYavh/WOyXcTbHky0EeLUwDZsLpRAY2Liv456BmWmyaJCSIMsDGTZmiYdyKBDv4+/XYjEsFUkYDyzaTRTcUZALP+6eoEnJJElxY9tAAQKWEqYUhNKSVZYCY+0tWqRVCsnLgxhTnK7snQMmb2cKsxpiTjkOqEW1E36NN9CoR0BmucIq8au4mcS3NV3KtZRmaJk+WIP5/UcL839I/bgnuZdvUi8vLshDGg18QdHw1pXZed9p5pnj7TmpWrjDCgBDV+Q4m9jiwR5YdjBeA5cVMm+tg4Z2aJmlq+gyZOmo2QubcwtCbPSykI2LF/MdJGljhvKT5MBibIIfzXUZDAzLdPT8dRgAXRmNQiqvuAwrQGoiKaeFf5KJVS3H0RLx5C8Wd9tRW0oVPCA+ln3qVxDlAeIXpzSKPlsRDqfR2pw== marcin.falkiewicz"
                ];
              };
            };

        };

	
        supportedFilesystems = [ "ext4" "xfs" ]; # add zfs for zfs support

        #zfs = {
        #    devNodes = "/dev/disk/by-id";
        #    extraPools = [ "zraid" ];
        #    enableUnstable = true;
        #};

        blacklistedKernelModules = [
            #"radeon" "amdgpu"
            "pcspkr" "wl"
            "b43" "b43legacy" "ssb" "bcm43xx"
            "brcm80211" "brcmfmac" "brcmsmac" "bcma"
        ];
    };

    fileSystems = {
        "/" = {
            options = [ "nodiscard" "noatime" "commit=120" ];
        };
        "/boot" = {
            options = [ "discard" "noatime" ];
        };
        "/home" = {
            device = "/dev/node/home";
            fsType = "ext4";
            options = [ "nodiscard" "noatime" ];
        };
        "/sys/firmware/efi/efivars" = {
            device = "efivarsfs";
            fsType = "efivarsfs";
            options = [ "ro" "nosuid" "nodev" "noexec" "noatime" ];
        };

        # Windows 10 partitions
        "/mnt/sda4" = {
            device = "/dev/sda4";
            fsType = "ntfs";
            options = [ "ro" ];
        };

        "/mnt/sda5" = {
            device = "/dev/sda5";
            fsType = "ntfs";
            options = [ "ro" ];
        };

	"/mnt/raid" = {
          device = "/dev/mapper/RAID";
            fsType = "xfs";
            options = [ "noatime" "nodev" "noexec" "allocsize=64m" ];
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
            requiredBy  = [ "basic.target" ];
        }
        { where = "/dev/hugepages/hugepages-1048576kB";
            enable  = true;
            what  = "hugetlbfs";
            type  = "hugetlbfs";
            options = "pagesize=1G";
            requiredBy  = [ "basic.target" ];
        }
    ];

    systemd.services = {
        sensors = {
            description = "Set min/max valuse for sensors";
            path = [ pkgs.lm_sensors ];
            enable = true;
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.lm_sensors}/bin/sensors -s";
            };
            wantedBy = ["multi-user.target"];
        };

        # service for fstrim.timer
        fstrim = {
            description = "Discard unused blocks";
            path = [ pkgs.utillinux ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.utillinux}/bin/fstrim -av";
            };
        };

        # service for nix-collect-garbage.timer
        nix-collect-garbage = {
            description = "Remove NixOS generation older than 14 days";
            path = [ pkgs.nix ];
            enable = false;
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d";
            };
        };
    };

    systemd.timers = {
        # do fstrim every week, instead of discard-on-delete
        fstrim = {
            description = "Discard unused blocks once a week";
            timerConfig = {
                OnCalendar = "weekly";
                AccuracySec = "6h";
                Unit = "fstrim.service";
                Persistent = true;
            };
            wantedBy = [ "timers.target" ];
        };

        # auto-clean generations older than 7 days, every week
        nix-collect-garbage = {
            description = "Remove old NixOS generations";
            enable = false;
            timerConfig = {
                OnCalendar = "weekly";
                AccuracySec = "6h";
                Unit = "nix-collect-garbage.service";
                Persistent = true;
            };
            before = [ "fstrim.timer" ];
            wantedBy = [ "timers.target" ];
        };
    };

    services.journald.extraConfig = ''
        Compress=yes
        SystemMaxUse=1024M
        SystemMaxFileSize=8M
    '';

    environment.etc."tmpfiles.d/intel_pstate.conf".text = ''
      w /sys/devices/system/cpu/intel_pstate/min_perf_pct   - - - - 26
      w /sys/devices/system/cpu/intel_pstate/max_perf_pct   - - - - 100

      #w /sys/kernel/mm/transparent_hugepage/enabled         - - - - always
      #w /sys/kernel/mm/transparent_hugepage/enabled         - - - - madvise
      w /sys/kernel/mm/transparent_hugepage/enabled         - - - - never
      w /sys/kernel/mm/transparent_hugepage/defrag          - - - - always
      w /sys/kernel/mm/transparent_hugepage/khugepaged/scan_sleep_millisecs - - - - 5000
      w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag   - - - - 1
    '';

    hardware.cpu.intel.updateMicrocode = true;

    services.udev.extraRules = ''
        # force disks stanby after 15 minutes
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -S0 -B255 /dev/%k"

        # default schedulers
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="deadline"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/fifo_batch}="24"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/writes_starved}="8"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/front_merges}="1"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue_depth}="1"
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq" # because im using zfs

        # fancy swap-on-zram rule
        ACTION=="add", KERNEL=="zram[0-9]", ATTR{comp_algorithm}="lzo", ATTR{disksize}="256M"
        ACTION=="add", KERNEL=="zram[0-9]", RUN+="${pkgs.busybox}/bin/mkswap /dev/%k"
        ACTION=="add", KERNEL=="zram[0-9]", RUN+="${pkgs.busybox}/bin/swapon -p1 /dev/%k"

        KERNEL=="zram[0-9]", SUBSYSTEM=="block", ENV{UDISKS_IGNORE}="1"

        KERNEL=="sda[1367]", SUBSYSTEM=="block", ENV{UDISKS_IGNORE}="1"
        KERNEL=="sd[bcde]2", SUBSYSTEM=="block", ENV{UDISKS_IGNORE}="1"
    '';

    security.rtkit.enable = true;
    security.pam.loginLimits = [
        { domain = "@audio"; type = "-"; item = "rtprio"; value = "99"; }
        { domain = "@audio"; type = "-"; item = "memlock"; value = "131072"; }
        { domain = "@libvirtd"; type = "-"; item = "rtprio"; value = "99"; }
        { domain = "@libvirtd"; type = "-"; item = "nice"; value = "-20"; }
    ];
    security.hideProcessInformation = true;

    system.stateVersion = "17.09";

    i18n = { # Select internationalisation properties and timezone
        consoleFont = "lat2-16";
        consoleKeyMap = "pl";
        defaultLocale = "en_US.UTF-8";
    };

    time.timeZone = "Europe/Warsaw";

    nix.nixPath = [ "/etc/nixos/nixpkgs" "nixpkgs=/etc/nixos/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" ];
    nix.extraOptions = ''
        build-cores = 4
        build-max-jobs = 4
        build-use-chroot = true

        #binary-caches = https://cache.nixos.org/
        binary-caches-parallel-connections = 4

        gc-keep-outputs = true
        gc-keep-derivations = true

        auto-optimise-store = true
    '';

}
