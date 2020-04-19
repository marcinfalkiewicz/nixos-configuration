# vim: ft=nix

{ config, pkgs, ... }:
let

    hostname = "GRID";

in
{
    networking = {
        hostName = "${hostname}";
        extraHosts = ''
          127.0.1.1 ${hostname}
    '';
        hostId = "6e003f24";
    usePredictableInterfaceNames = true;

        wireless.enable = false;
        tcpcrypt.enable = false;
        networkmanager.enable = true;
        networkmanager.unmanaged = [ "eth0" "enp6s0br" "virbr0" "virbr1" ];

    firewall = {
        enable = true;
        allowedTCPPorts = [
            # samba
            139 445
            # ssh
            2538 2539
            # steam (in-home streaming)
            27036 27037
            # transmission
            9091
            60450
            # wg
            54091
            54092
            # opentracker
            6969
        ];
        allowedTCPPortRanges = [
            { from = 1714; to = 1764; }
        ];
        allowedUDPPorts = [
            27031 27036 # steam (in-home streaming)
            34197 # factorio
            54091 # wg
        ];
        allowedUDPPortRanges = [
            { from = 1714; to = 1764; }
        ];
        logRefusedConnections = false;
        trustedInterfaces = [ "virbr0" ];
    };

    wireguard.interfaces.wg-digitalocean = {
        ips = [ "10.250.0.10/24" ];
        listenPort = 54091;
        privateKeyFile = "/root/wireguard/privatekey";
        peers = [ {
            allowedIPs = [ "10.250.0.0/24" ];
            endpoint = "example.com:52291";
            persistentKeepalive = 30;
            publicKey = "";
            presharedKeyFile = "/root/wireguard/psk";
        }];
    };
    };
}
