#
{ config, pkgs, ... }:

{
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  users = {
    users.root = {
      openssh.authorizedKeys.keys = [ ];
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.dweller = {
      isNormalUser = true;
      description = "Marcin Falkiewicz";
      uid = 1000;
      home = "/home/dweller";
      shell = "/run/current-system/sw/bin/bash";
      createHome = true;
      extraGroups = [
        "wheel" "networkmanager"
        "transmission"
      ]
      ++ pkgs.stdenv.lib.optionals config.programs.sway.enable [ "sway" ]
      ++ pkgs.stdenv.lib.optionals config.virtualisation.libvirtd.enable [ "libvirtd" ]
      ++ pkgs.stdenv.lib.optionals config.virtualisation.docker.enable [ "docker" ]
      ++ pkgs.stdenv.lib.optionals config.services.transmission.enable [ "transmission" ];
      packages = with pkgs; [
        steam discord mattermost-desktop
        vlc qbittorrent virtmanager krusader chromium
        # tools
        openssl neofetch ldapvi khal
      ];
    };

    users.clamav = { extraGroups = [ "transmission" ]; };
    extraGroups = {
      transmission = { gid = 70; };
      hugepages = { gid = 8; };
    };

  };
  security.pam.services."dweller".enableKwallet = true;
}
