
{ config, pkgs, ... }:

{

    networking.firewall = {
        enable = true;
        allowedTCPPorts = [
            # samba
            139 445
            # openssh
            2538
            # nix-serve
            5000
        ];
        logRefusedConnections = false;
        trustedInterfaces = [ "virbr0" ];
    };
}
