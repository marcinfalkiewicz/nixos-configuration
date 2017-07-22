#
{ config, pkgs, ... }:

{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dweller = {
    isNormalUser = true;
    description = "Marcin Falkiewicz";
    uid = 1000;
    home = "/home/dweller";
    shell = "/run/current-system/sw/bin/bash";
    createHome = true;
    extraGroups = [
      "wheel"
      "libvirtd"
      "networkmanager"
      "transmission"
    ];
  };

  users.users.clamav = {
      extraGroups = [ "transmission" ];
  };
}
