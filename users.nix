{ config, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.dweller = {
    isNormalUser = true;
    description = "Marcin Falkiewicz";
    uid = 1100;
    home = "/var/home/dweller";
    shell = "/run/current-system/sw/bin/bash";
    createHome = true;
    extraGroups = [
      "wheel"
      "libvirtd"
      "networkmanager"
    ];
  };

  #users.extraUsers.libvirt = {
  #  isNormalUser = false;
  #  isSystemUser = true;
  #  home = "/var/lib/libvirt";
  #  shell = "/run/current-system/sw/bin/nologin";
  #  extraGroups = [ "libvirtd" "hugepages" ];
  #};

  users.extraGroups.hugepages = {
      gid = 8;
  };
}
