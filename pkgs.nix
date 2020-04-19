#
{ config, pkgs, lib, ... }:

{

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

    alloc_hugepages()
    {
      while [ $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages) != $1 ];
      do
        echo $1 | sudo tee /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages > /dev/null
        echo -en "Allocated hugepages: $(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)/$1\r"
        sleep 1
      done
    }

    iommu_groups_list()
    {
      shopt -s nullglob
      for g in /sys/kernel/iommu_groups/*;
      do
          echo "IOMMU Group $\{g##*/\}:"
          for d in $g/devices/*;
          do
              echo -e "\t$(lspci -qnns $\{d##*/\})"
          done
      done
    }

    amdgpu_fanspeed()
    {
      echo $1 | sudo tee /sys/class/drm/card0/device/hwmon/hwmon0/pwm1
    }

    remount_swap()
    {
      for i in $(tail -n+2 /proc/swaps | awk '{print $1}'); do
        sudo swapoff $i
        sudo swapon -d $i
        sync
        echo 3 | sudo tee /proc/sys/vm/drop_caches
        sync; sync; sync
      done
    }

    #sensors()
    #{
    #  ${pkgs.lm_sensors}/bin/sensors -c /etc/sensors.conf $@
    #}

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
    allowBroken = true;
    withGnome = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelPatches = [
    {
      name = "ukms-5.5.patch";
      patch = pkgs.fetchpatch {
        url = https://raw.githubusercontent.com/dolohow/uksm/master/v5.x/uksm-5.5.patch;
        sha256 = "01z1zkbgi07spb9nqxaqs9mwbngck27rxfrhxx02svkav8xn10mx";
      };
      extraConfig = ''
        UKSM y
      '';
    }
    {
      # Revert: mm/filemap.c: don't initiate writeback if mapping has no dirty pages
      name = "0000-revert-f4bdb2697ccc9cecf1a9de86905c309ad901da4c.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/0000-revert-f4bdb2697ccc9cecf1a9de86905c309ad901da4c.patch;
        sha256 = "0zl4xjyl1a7k1kpjbphkflr665v0cjc94arcmijvxd25hrid2knq";
      };
    }
    {
      name = "enable_additional_cpu_optimizations";
      patch = pkgs.fetchpatch {
        url = https://raw.githubusercontent.com/graysky2/kernel_gcc_patch/master/enable_additional_cpu_optimizations_for_gcc_v9.1+_kernel_v5.5+.patch;
    sha256 = "1pakk8fczlsgfqg4nd8n8vl5j0fma5bsadjhybnqjzrzcr4c06ip";
      };
      extraConfig = ''
        MZEN y
      '';
    }
    {
      name = "enable_o3_global_optimizations";
      patch = pkgs.fetchpatch {
        url = https://gitlab.com/post-factum/pf-kernel/-/commit/cf7a8ad26e0bd6ca8afba89f53d2e9dc43ee2598.diff;
    sha256 = "0sb32mz41n7bwb1lx9r0zjwj4nf7ailyhvnw302vcvnqxay7kk5m";
      };
      extraConfig = ''
        CC_OPTIMIZE_FOR_PERFORMANCE_O3 y
      '';
    }
    {
      name = "0101-i8042-decrease-debug-message-level-to-info.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0101-i8042-decrease-debug-message-level-to-info.patch;
        sha256 = "09larh6vmqdqm70nxxjrc07i7l724kff6grl14ij674c83cqsg83";
      };
    }
    {
      name = "0102-Increase-the-ext4-default-commit-age.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0102-Increase-the-ext4-default-commit-age.patch;
        sha256 = "0kdpci5k9x21aj4dgww3ydsx89zr68d0nk5q0z786ymc2b0ahxc2";
      };
    }
    {
      name = "0103-silence-rapl.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0103-silence-rapl.patch;
        sha256 = "14qci0w18224p1i29wi3pk5x09g7j7cjh8rpldb9bz3122vb9ps0";
      };
    }
    {
      name = "0104-pci-pme-wakeups.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0104-pci-pme-wakeups.patch;
        sha256 = "1jhl2iwhkjsmlihb1kkdw4vwvranb7x6lm5y3w0d4y06rlba3zjs";
      };
    }
    {
      name = "0105-ksm-wakeups.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0105-ksm-wakeups.patch;
        sha256 = "0dyppzcyisbgvj38rhgw5pcfnxgx19yp2fk3rpps2a5rmr015jcm";
      };
    }
    {
      name = "0106-intel_idle-tweak-cpuidle-cstates.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0106-intel_idle-tweak-cpuidle-cstates.patch;
        sha256 = "07swndj6z8v5gl688f0m01c44diw961g6ys1przx6d5ckbrcmz6s";
      };
    }
    {
      name = "0107-bootstats-add-printk-s-to-measure-boot-time-in-more-.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0107-bootstats-add-printk-s-to-measure-boot-time-in-more-.patch;
        sha256 = "0567xn15zjbrn45mvjyilinqdaw15wzmd2vy1v6zkpgdbf3l6xq4";
      };
    }
    {
      name = "0108-smpboot-reuse-timer-calibration.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0108-smpboot-reuse-timer-calibration.patch;
        sha256 = "09wi4g44whpx5dbbkf9svylmlwiiaswpcznv8yhz1vnsd85h6plk";
      };
    }
    {
      name = "0109-raid6-add-Kconfig-option-to-skip-raid6-benchmarking.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0109-raid6-add-Kconfig-option-to-skip-raid6-benchmarking.patch;
        sha256 = "1cahp4ldzlvpv454546dbgv9p7w06zn3cdbhyq06khvpqmwcr294";
      };
    }
    {
      name = "0110-Initialize-ata-before-graphics.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0110-Initialize-ata-before-graphics.patch;
        sha256 = "0zsnm6f1h9nnm1xyyyzmpinjdhhfc44n6akbbjnvgb56xkmvl983";
      };
    }
    {
      name = "0111-give-rdrand-some-credit.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0111-give-rdrand-some-credit.patch;
        sha256 = "0jipf9mj5qk8hnw8kp1lqbl247jqpk6lr18hrblkifgyjgnmfpbm";
      };
    }
    {
      name = "0112-ipv4-tcp-allow-the-memory-tuning-for-tcp-to-go-a-lit.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0112-ipv4-tcp-allow-the-memory-tuning-for-tcp-to-go-a-lit.patch;
        sha256 = "0sglnd9d1i1zqdmcss1r0wsjwry6g4l9kf1i8v5nl5nspymcwc1i";
      };
    }
    {
      name = "0113-kernel-time-reduce-ntp-wakeups.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0113-kernel-time-reduce-ntp-wakeups.patch;
        sha256 = "1d0bddqcgmg81409gw9763f3w46c2wa1jk5mqgw2gh9vm6jakl53";
      };
    }
    {
      name = "0114-init-wait-for-partition-and-retry-scan.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0114-init-wait-for-partition-and-retry-scan.patch;
        sha256 = "0ik3yvr0zyqqdl5pf6d8snvqj26811y337l7w8hd66yq2mbapj6g";
      };
    }
    {
      name = "0115-print-fsync-count-for-bootchart.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0115-print-fsync-count-for-bootchart.patch;
        sha256 = "12qqf9wz9hidizw9gdmnb2ja3n991bykp9jigfm5z7li9xgyr0jc";
      };
    }
    #{
    #  name = "0116-Add-boot-option-to-allow-unsigned-modules.patch";
    #  patch = pkgs.fetchpatch {
    #    url = file:///etc/nixos/kernel/clearlinux-patchset/0116-Add-boot-option-to-allow-unsigned-modules.patch;
    #    sha256 = "11ghdr0sydvp86752wm13y5q9a6mz83y60szqbfah3ksmxz6h9ah";
    #  };
    #}
    {
      name = "0117-Enable-stateless-firmware-loading.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0117-Enable-stateless-firmware-loading.patch;
        sha256 = "0ky6m4cr4xkkdrbkyiwvrjwmkzypysdbaizp8y207r088nidnjaz";
      };
    }
    {
      name = "0118-Migrate-some-systemd-defaults-to-the-kernel-defaults.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0118-Migrate-some-systemd-defaults-to-the-kernel-defaults.patch;
        sha256 = "1pck5r6xs47gbzdr5qhy27m7f16xmxlck0fcir2rbjy3yrcwax5s";
      };
    }
    {
      name = "0119-xattr-allow-setting-user.-attributes-on-symlinks-by-.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0119-xattr-allow-setting-user.-attributes-on-symlinks-by-.patch;
        sha256 = "0m50xq2l8w6xnqrilvrgl4hd5ixfbksqxmzdrk7mn4xahcdqy3ry";
      };
    }
    {
      name = "0120-add-scheduler-turbo3-patch.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0120-add-scheduler-turbo3-patch.patch;
        sha256 = "054hvhaw128rv3b9l0f9zraf8sz0jdx3jvnfksvfnpldmnzhpfsb";
      };
    }
    {
      name = "0121-use-lfence-instead-of-rep-and-nop.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0121-use-lfence-instead-of-rep-and-nop.patch;
        sha256 = "1fzjvayclk98l00d2wspi7h6qsm8m83ipqrghj7ys8db7pdi7phm";
      };
    }
    {
      name = "0122-do-accept-in-LIFO-order-for-cache-efficiency.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0122-do-accept-in-LIFO-order-for-cache-efficiency.patch;
        sha256 = "08ypcna2vaxkw3l88pr5a1mmdjp9lhx9pkwka73q3fav48wdj77x";
      };
    }
    #{
    #  name = "0123-zero-extra-registers.patch";
    #  patch = pkgs.fetchpatch {
    #    url = file:///etc/nixos/kernel/clearlinux-patchset/0123-zero-extra-registers.patch;
    #    sha256 = "1ysg2nvzl29ls8w42gdi1hpvg6k06ddx4iiikvpdm856bh1bxa1d";
    #  };
    #}
    {
      name = "0124-locking-rwsem-spin-faster.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0124-locking-rwsem-spin-faster.patch;
        sha256 = "0hsnzavlqxhz667rhpyavixalqk6lfg3wchv1xxaq5b6diykpmhc";
      };
    }
    {
      name = "0125-ata-libahci-ignore-staggered-spin-up.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0125-ata-libahci-ignore-staggered-spin-up.patch;
        sha256 = "16wbyk6mqjq4j0rl1286mqpd66p8fw5j959xzy6jdqc8ci1bw83d";
      };
    }
    {
      name = "0126-print-CPU-that-faults.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0126-print-CPU-that-faults.patch;
        sha256 = "0akynf2fd29d0arph6d4p3gvfyyw73labfhvyws6v0qwmfm1rs5c";
      };
    }
    {
      name = "0127-x86-microcode-Force-update-a-uCode-even-if-the-rev-i.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0127-x86-microcode-Force-update-a-uCode-even-if-the-rev-i.patch;
        sha256 = "0zi72r4sr5kj35h9qq8jav9l77dfv29l9hwqsxz1dcfxb727zxv8";
      };
    }
    {
      name = "0128-x86-microcode-echo-2-reload-to-force-load-ucode.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0128-x86-microcode-echo-2-reload-to-force-load-ucode.patch;
        sha256 = "00lqi1g99yb15n9652x18x86fw2mmpx1r5wm959v83r8kn3r4kzs";
      };
    }
    {
      name = "0129-fix-bug-in-ucode-force-reload-revision-check.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0129-fix-bug-in-ucode-force-reload-revision-check.patch;
        sha256 = "1xmwn1i1031hxd7i1ak4al78pjw6l1y196nbgv6a2a82brc9vkna";
      };
    }
    {
      name = "0130-nvme-workaround.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0130-nvme-workaround.patch;
        sha256 = "1svfan510yc3kglg9br596n3v624q7p43f6w6077axwbbb20ynrf";
      };
    }
    {
      name = "0131-Don-t-report-an-error-if-PowerClamp-run-on-other-CPU.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0131-Don-t-report-an-error-if-PowerClamp-run-on-other-CPU.patch;
        sha256 = "0ykwcj8ilja9ijv1vvf81pk1d455cfkjxg18h1plva73fwjss4jk";
      };
    }
    {
      name = "0132-overload-on-wakeup.patch";
      patch = pkgs.fetchpatch {
        url = file:///etc/nixos/kernel/clearlinux-patchset/0132-overload-on-wakeup.patch;
        sha256 = "019csmcz58fvhj5vppg304xa4xk8fvlx16wvaz1qw1xdhqq2sgsz";
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    config.boot.kernelPackages.cpupower
    #config.boot.kernelPackages.perf
    #config.boot.kernelPackages.sysdig
    #config.boot.kernelPackages.systemtap

    nix-prefetch-scripts
    tmux vim

    smartmontools hdparm hddtemp
    efibootmgr gptfdisk multipath_tools
    thin-provisioning-tools ntfs3g ddrescue

    pciutils
    usbutils

    mc ncdu
    htop iotop sysstat psmisc lsof audit
    zip unzip unrar pigz pxz pigz lzop p7zip
    file bc tree which
    git

    iftop tcpdump nmap tshark dnsutils
    iperf aria aria2 wget curl
    ethtool bridge-utils

    lm_sensors

    cryptsetup
    samba cifs-utils

    #python27
    neovim
    shellcheck libxml2 # for lint
  ]
  ++ stdenv.lib.optionals config.services.xserver.enable [
    redshift scrot i3lock libnotify
    alacritty
    # user control
    thunderbird gajim
    seafile-client keepassxc tigervnc spotify #firefox mpv
    pavucontrol
    xdotool xorg.xwininfo xorg.xkill
  ]
  ++ stdenv.lib.optionals config.services.xserver.windowManager.xmonad.enable [
    feh neofetch compton stalonetray
    haskellPackages.xmobar
  ]
  ++ stdenv.lib.optionals config.services.xserver.desktopManager.plasma5.enable [
    redshift-plasma-applet
    kdeconnect
    #bluedevil
    latte-dock
    akonadi
    #plasma-vault
    #plasma-browser-integration
    kdeApplications.kontact
    kdeApplications.kdepim-runtime
    #kdeApplications.kdepim-addons
    kdeApplications.kdepim-apps-libs
    kdeApplications.kmail
    kdeApplications.kmail-account-wizard
    kdeApplications.kmailtransport
    spamassassin
    kdeApplications.baloo-widgets
    kdeApplications.dolphin
    kdeApplications.dolphin-plugins
    kdeApplications.kate
    kdeApplications.ark
    kdeApplications.kwalletmanager
    kdeApplications.gwenview
    kdeApplications.okular
    kdeApplications.kcalc
    kdeApplications.filelight
    #qtcurve
    #adwaita-qt
  ]
  ++ stdenv.lib.optionals config.services.xserver.desktopManager.pantheon.enable [
    pantheon.elementary-session-settings
  ]
  ;

  programs.bash.enableCompletion = true;
  programs.nano.nanorc =
    ''
    set nowrap
    set tabstospaces
    set tabsize 2
    '';

  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      firefox = "${lib.getBin pkgs.firefox}/bin/firefox";
      mpv = "${lib.getBin pkgs.mpv}/bin/mpv";
      #spotify = "${lib.getBin pkgs.spotify}/bin/spotify";
    };
  };

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
    #fontconfig.ultimate = {
    #  enable = true;
    #};
  };

  services.printing.enable = false;
  services.xserver = {
    autorun = true;
    enable = true;
    layout = "pl";
    libinput.enable = true;
    #xkbOptions = "eurosign:e";
    xkbOptions = "shift:both_capslock, ctrl:nocaps, terminate:ctrl_alt_bksp";

    videoDrivers = [
      #"nvidia"
      "amdgpu"
    ];
    screenSection = ''
      #Option "metamodes" "nvidia-auto-select +0+0 { ForceCompositionPipeline = On }"
      Option "TearFree" "true"
      Option "VariableRefresh" "true"
    '';
    #deviceSection = ''
    #  VendorName "NVIDIA Corporation"
    #  BoardName "EVGA GeForce GTX 1080 Ti"
    #  BusID  "PCI:8:0:0"
    #  Option "DRI" "3"
    #  Option "TripleBuffer" "True"
    #'';
  };

  services.xserver.displayManager.defaultSession = "plasma5";
  services.xserver.displayManager.gdm.wayland = false;
  services.xserver.displayManager.sddm = {
    enable = true;
    autoNumlock = true;
    autoLogin = { enable = true; user = "dweller"; };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.plasma5.xdg-desktop-portal-kde ];
    gtkUsePortal = true;
  };
  services.xserver.desktopManager = {
    plasma5.enable = true;
    gnome3.enable = false;
    pantheon.enable = false;
  };
  services.xserver.windowManager.xmonad = {
    enable = false;
    extraPackages = haskellPackages:
    [
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad-extras
      haskellPackages.xmobar
    ];
  };

  hardware.opengl = {
    extraPackages = [
    pkgs.vaapiIntel
    pkgs.vaapiVdpau
        pkgs.vulkan-loader
    ];
    driSupport32Bit = true;
    s3tcSupport = true;
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    extraClientConf = ''
load-module module-dbus-protocol
load-module module-udev-detect tsched=0 use_ucm=0
    '';
  };
  hardware.bluetooth.enable = true;
}
