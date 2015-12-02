
{ config, pkgs, ... }:

{

    networking.firewall = {
        enable = true;
        allowedTCPPorts = [
            # samba
            139 445
            # openssh
            2538
        ];
        logRefusedConnections = false;
        trustedInterfaces = [ "virbr0" ];
    };
}
