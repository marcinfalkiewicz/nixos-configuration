# vim: ft=nix
{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    enableKVM = true;
    enableOVMF = true;

    qemuConfig = ''
        security_driver = "none"
    '';
  };
}
