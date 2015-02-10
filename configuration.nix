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

  # Use the gummiboot efi boot loader.
  boot = {
    vesa = false;

    loader = {
      gummiboot.enable = true;
      gummiboot.timeout = 1;
      efi.canTouchEfiVariables = true;
    };

    kernel.sysctl = {
        "kernel.dmesg_restrict" = 1;

        # vm memory assignment
        "vm.nr_overcommit_hugepages" = 7700;
        "vm.hugetlb_shm_group" = 8;
    };

    #kernelPackages = pkgs.linuxPackages_3_18;
    kernelPackages = pkgs.linuxPackages_custom {
        version = "3.19.0-HYDRA";
        src = pkgs.fetchurl {
            url = "mirror://kernel/linux/kernel/v3.x/linux-3.19.tar.xz";
            sha256 = "be42511fe5321012bb4a2009167ce56a9e5fe362b4af43e8c371b3666859806c";
        };
        configfile = /etc/nixos/kernel.config;
    };

    #extraModulePackages = [ "" ];
    kernelModules = [ "kvm-intel" "pci-stub" "vfio-pci" ];
    kernelParams = [
      #"video=efifb"
      "iommu=pt"
      "intel_iommu=on,igfx_off"
      "pci-stub.ids=1002:6818,1002:aab0"
    ];

    extraModprobeConfig = ''
      options kvm                 ignore_msrs=1
      options kvm_intel           enable_apicv=1
      options kvm_intel           ept=1
      options kvm_intel           emulate_invalid_guest_state=0
      options vfio_iommu_type1    allow_unsafe_interrupts=0

      options snd-hda-intel       beep_mode=0
      options snd-hda-intel       enable_msi=1
      options snd-hda-intel       power_save=30
      options snd-hda-intel       power_save_controller=1

      options usbcore             autosuspend=30
    '';


    initrd.kernelModules = [ "fbcon" "i915" ];
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "usbhid" "usb_storage" "btrfs" ];
    initrd.supportedFilesystems = [ "btrfs" ];
    blacklistedKernelModules = [ "radeon" "pcspkr" "wl" ];

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
      options = "noatime,compress=zlib,space_cache,inode_cache";
    };

    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
      options = "noatime,noauto,x-systemd.automount";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 12;
    numDevices = 8;
  };

  swapDevices = [ ];

  hardware.cpu.intel.updateMicrocode = false;

  networking.hostName = "hydra";
  networking.hostId = "3964c893";
  networking.wireless.enable = false;
  networking.networkmanager.enable = true;

  # Select internationalisation properties and timezone
  i18n = {
    consoleFont = "lat2-16";
    consoleKeyMap = "pl";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "Europe/Warsaw";

  nix.extraOptions = ''
    build-cores = 8
  '';

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


}
