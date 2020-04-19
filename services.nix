# vim: ft=nix

{ config, pkgs, ... }:

{

  virtualisation = {
    libvirtd = {
      enable = true;
      qemuOvmf = true;
      qemuPackage = pkgs.kvm;
      qemuVerbatimConfig = ''
        namespaces = []
        security_driver = "none"
      '';
    };
    docker = { enable = true; autoPrune.enable = true; };
    anbox = { enable = false; };
  };

  systemd.services.irqbalance.environment = { IRQBALANCE_BANNED_CPUS = "AAAA"; };
  #systemd.services.syncthing.serviceConfig = { CPUAccounting = true; CPUQuota = "15%"; };
  services = {
    ntp.enable = false;
    irqbalance.enable = true;
    haveged.enable = true;
    fwupd.enable = true;
    earlyoom.enable = true;
    earlyoom.freeMemThreshold = 10;
    usbguard.enable = true;
    usbguard.IPCAllowedGroups = [ "wheel" ];

    nix-serve.enable = false;
    gpm.enable = false;

    clamav = {
      daemon.enable = true;
      updater.enable = true;
      updater.frequency = 7;
    };

    openssh = {
      enable = true;
      ports = [ 2538 ];
      listenAddresses = [
        { addr = "0.0.0.0"; port = 2538; }
      ];
      permitRootLogin = "no";
      forwardX11 = false;
    };

    syncthing = {
      enable = false;
    };
  };

}
