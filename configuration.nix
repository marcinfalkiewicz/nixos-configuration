#
{ config, pkgs, ... }:

let

  hostname = "GRID";

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
            ./services.nix
        ];

    boot = {
        # Use the gummiboot efi boot loader.
        vesa = false;

        loader = {
            timeout = 10;

            systemd-boot.enable = true;
            efi.canTouchEfiVariables = true;
        };

        kernel.sysctl = {
            # vm memory assignment
            "vm.nr_overcommit_hugepages" = 5120;
            "vm.hugetlb_shm_group" = 8;

            "kernel.dmesg_restrict" = 1;
            #"kernel.kptr_restrict" = 1;
            "kernel.nmi_watchdog" = 0;

            "kernel.sched_rt_period_us" = 1000000;
            "kernel.sched_rt_runtime_us" = 900000;

            "vm.dirty_background_bytes" = 16777216;
            "vm.dirty_bytes" = 50331648;

            # disable ipv6
            "net.ipv6.conf.default.disable_ipv6" = 1;
            "net.ipv6.conf.all.disable_ipv6" = 1;
            "net.ipv6.conf.lo.disable_ipv6" = 1;

        };

    # breaks compilation more often than not
        tmpOnTmpfs = false;
        cleanTmpDir = true;

        kernelModules = [
            #"kvm-intel"
            "kvm-amd"
            "vfio_pci" "vfio_iommu_type1"
            "vhost" "vhost_net" "vhost_scsi"
            "zram"
            "coretemp" "nct6775" "i2c_i801" "i801_smbus"
        "br_netfilter" "macvtap"
        ];

        kernelParams = [ #"video=efifb"
            "clocksource=tsc" # or hpet
            "iommu=pt"
            "amd_iommu=on"
            "processor.max_cstate=5"
            #"ip=dhcp"
        "vfio_pci.ids=10de:1b06,10de:10ef"  # GTX 1080 Ti
            #"vfio_pci.ids=1002:6818,1002:aab0"  # AMD HD7870
            #"vfio_pci.ids=1002:67df,1002:aaf0"  # AMD RX480
            #"hugepagesz=1GB"
            #"hugepages=16"
            "hugepagesz=2MB"
            "hugepages=8192"
            ## HT Enabled
            "isolcpus=8-15"
            "nohz_full=1-15"
            #"rcu_nocbs=1,3,5,7,9,11,13,15"
            "rcu_nocbs=0-15"
        # HT Disabled
            #"isolcpus=2,3,4,5,6,7,10,11,12,13,14,15"
            #"nohz_full=2,3,4,5,6,7,10,11,12,13,14,15"
            #"rcu_nocbs=2,3,4,5,6,7,10,11,12,13,14,15"
        ];

        extraModprobeConfig = ''
options loop                max_loop=8

softdep nouveau             pre: vfio-pci
softdep nvidia              pre: vfio-pci
softdep radeon              pre: vfio-pci
softdep amdgpu              pre: vfio-pci
options vfio_pci            disable_vga=1

options i915                fastboot=0
options i915                enable_rc6=7
options i915                semaphores=1

options amdgpu          gpu_recovery=1
options amdgpu          lbpw=1
options amdgpu          dpm=1

options nvidia-drm          modeset=1

options kvm                 ignore_msrs=1
options kvm                 report_ignored_msrs=0
options kvm                 kvmclock_periodic_sync=1

options kvm_amd         avic=1
options kvm_amd         npt=1

options kvm_intel           enable_apicv=1
options kvm_intel           ept=1
options kvm_intel           fasteoi=1
options kvm_intel           emulate_invalid_guest_state=0
options vfio_iommu_type1    allow_unsafe_interrupts=0

options processor           ignore_ppc=1

options snd-hda-intel       beep_mode=0
options snd-hda-intel       enable_msi=1
options snd-hda-intel       power_save=30
options snd-hda-intel       power_save_controller=1

options igb         max_vfs=2

options usbcore             autosuspend=30

options libata              ignore_hpa=0
options libata              allow_tpm=0
options libahci             skip_host_reset=1
options libahci             ignore_sss=1
options libahci             devslp_idle_timeout=300
options scsi_mod        use_blk_mq=1
        '';

        initrd = {
            checkJournalingFS = true;
            kernelModules = [
              "amdgpu" "loop" "vfio-pci" "igb" "msr"
            ];
            availableKernelModules = [
          "fbcon" "igb"
              "amdgpu"
              "ehci_pci" "ahci" "usbhid" "usb_storage"
              "dm_mod" "dm_crypt" "md_mod" "raid10"
              "aesni_intel" "algif_skcipher" "af_alg"
             ];
            supportedFilesystems = [ "ext4" "xfs" ];
            #mdadmConf = "
            #  DEVICE partitions
            #  ARRAY /dev/md0 metadata=1.2 name=NODE:0 UUID=70c2f80c:4538004f:e9b15630:810e5f43
            #";
            #compressor = "xz -9";

            network = {
              enable = false;

              ssh = {
                enable = true;
                port = 2539;
                hostRSAKey = /etc/nixos/initrd/host_rsa_key;
                authorizedKeys = [ ];
              };
            };

        };


        supportedFilesystems = [ "ext4" "xfs" "nfs" ];
        blacklistedKernelModules = [
            "pcspkr" "wl"
            "b43" "b43legacy" "ssb" "bcm43xx"
            "brcm80211" "brcmfmac" "brcmsmac" "bcma"
            "radeon" "amdgpu"
        "sp5100_tco" # disabled in hardware
            "nouveau" "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" "nvidiafb"
        ];
    };

    swapDevices = [
    { device = "/dev/disk/by-partuuid/dcfe708f-a22e-4c28-ac64-81387755a17b";
      encrypted.label = "luks-swap";
          randomEncryption = {
        cipher = "serpent-xts-plain64";
        enable = true;
            source = "/dev/urandom";
          };
    }
     ];
    zramSwap = {
      enable = true;
      numDevices = 1;
      algorithm = "zstd";
      priority = 100;
      memoryPercent = 9;
    };

    fileSystems = {
        "/" = {
            options = [ "nodiscard" "noatime" "commit=120" ];
        };
        "/boot" = {
            options = [ "discard" "noatime" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=60s" "x-systemd.device-timeout=30s" ];
        };
        "/home" = {
            device = "/dev/mesh/home";
            fsType = "ext4";
            options = [ "nodiscard" "noatime" ];
        };

        # Windows 10 partitions
        "/mnt/sda4" = {
            device = "/dev/sda4";
            fsType = "ntfs";
            options = [ "ro" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=60s" ];
        };

        "/mnt/sda6" = {
            device = "/dev/sda6";
            fsType = "ntfs";
            options = [ "ro" "noauto" "x-systemd.automount" "x-systemd.idle-timeout=60s" ];
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
        zenstates = {
            description = "Set Ryzen CPUs P-States";
            enable = true;
            path = [ pkgs.python ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "/usr/bin/zenstates.py --c6-disable";
            };
            before = [ "basic.target" ];
            after = [ "sysinit.target" "local-fs.target" "suspend.target" "hibernate.target" ];
            wantedBy = [ "basic.target" "suspend.target" "hibernate.target" ];
        };

        sensors = {
            description = "Set min/max valuse for sensors";
            enable = false;
            path = [ pkgs.lm_sensors ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.lm_sensors}/bin/sensors -s";
            };
            wantedBy = [ "multi-user.target" ];
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
            enable = false;
            path = [ pkgs.nix ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 14d";
            };
        };
        nix-repair = {
            description = "Check and repair Nix store";
            enable = true;
            path = [ pkgs.nix ];
            serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.nix}/bin/nix-store --verify --check-contents --repair";
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
        nix-repair = {
            description = "Check and repair Nix store";
            enable = true;
            timerConfig = {
                OnCalendar = "daily";
                AccuracySec = "6h";
                Unit = "nix-repair.service";
                Persistent = true;
            };
            before = [ "fstrim.timer" ];
            wantedBy = [ "timers.target" ];
        };
    };

    services.journald.extraConfig = ''
        Storage=persistent
    Compress=yes
        SystemMaxUse=1024M
        SystemMaxFileSize=8M
    '';

    environment.etc."tmpfiles.d/thp.conf".text = ''
      w /sys/kernel/mm/transparent_hugepage/enabled         - - - - never
    '';
    hardware.ksm.enable = true;
    hardware.ksm.sleep = 50;

    powerManagement.cpuFreqGovernor = "schedutil";
    powerManagement.powerUpCommands = ''
      # set amdgpu fan control to auto
      ${pkgs.coreutils}/bin/echo 2 | ${pkgs.coreutils}/bin/tee /sys/class/drm/card0/device/hwmon/hwmon0/pwm1_enable
    '';
    powerManagement.powerDownCommands = ''
      sync
      ${pkgs.coreutils}/bin/echo 3 | ${pkgs.coreutils}/bin/tee /proc/sys/vm/drop_caches
      sync
    '';

    hardware.cpu.amd.updateMicrocode = true;
    hardware.mcelog.enable = false;

    services.udev.extraRules = ''
        # force disks stanby after 15 minutes
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", RUN+="${pkgs.hdparm}/bin/hdparm -S0 -B255 /dev/%k"

        # default schedulers
        ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="deadline"
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/fifo_batch}="24"
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/writes_starved}="8"
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/iosched/front_merges}="1"
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue_depth}="1"
        #ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq" # because im using zfs

        # fancy swap-on-zram rule
        #ACTION=="add", KERNEL=="zram[0-9]", ATTR{comp_algorithm}="lz4hc", ATTR{disksize}="64M"
        #ACTION=="add", KERNEL=="zram[0-9]", RUN+="${pkgs.busybox}/bin/mkswap /dev/%k"
        #ACTION=="add", KERNEL=="zram[0-9]", RUN+="${pkgs.busybox}/bin/swapon -p1 /dev/%k"

        KERNEL=="zram[0-9]", SUBSYSTEM=="block", ENV{UDISKS_IGNORE}="1"
        KERNEL=="sda*", SUBSYSTEM=="block", ENV{UDISKS_IGNORE}="1"
    '';

    security.rtkit.enable = true;
    security.pam.loginLimits = [
        { domain = "@audio"; type = "-"; item = "rtprio"; value = "99"; }
        { domain = "@audio"; type = "-"; item = "memlock"; value = "131072"; }
        { domain = "@libvirtd"; type = "-"; item = "rtprio"; value = "99"; }
        { domain = "@libvirtd"; type = "-"; item = "nice"; value = "-20"; }
    ];
    security.hideProcessInformation = true;

    system.stateVersion = "18.09";

    console = {
      earlySetup = true;
      font = "lat2-16";
      keyMap = "pl";
    };

    i18n.defaultLocale = "en_US.UTF-8";

    time.timeZone = "Europe/Warsaw";

    nix = {
      #nixPath = [ "/etc/nixpkgs" "nixpkgs=/etc/nixpkgs" "nixos-config=/etc/nixos/configuration.nix" ];
      useSandbox = true;
      maxJobs = 2;
      buildCores = 8;
      autoOptimiseStore = true;
      extraOptions = ''
          #build-use-chroot = true
          binary-caches-parallel-connections = 4
          #gc-keep-outputs = true
          #gc-keep-derivations = true
      '';
    };

}
