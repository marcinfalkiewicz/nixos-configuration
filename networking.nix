{ config, pkgs, ... }:
let

    hostname = "NODE";

in
{
    networking = {
        hostName = "${hostname}";
        extraHosts = ''127.0.1.1 ${hostname}'';
        hostId = "6e003f24";
        wireless.enable = false;
	firewall = {
		enable = true;
		allowedTCPPorts = [
			# samba
			139 445
			# steam (in-home streaming)
			27036 27037
			# transmission
			9091
		];
		allowedTCPPortRanges = [
			{ from = 1714; to = 1764; }
		];
		allowedUDPPorts = [
			# steam (in-home streaming)
			27031 27036
		];
		allowedUDPPortRanges = [
			{ from = 1714; to = 1764; }
		];
		logRefusedConnections = false;
		trustedInterfaces = [ "virbr0" ];
	};

        networkmanager.enable = false;
        networkmanager.unmanaged = [ "enp0s25" "enp0s25br" ];

        bridges.enp0s25br.interfaces = [ "enp0s25" ];

        interfaces.enp0s25.useDHCP = false;
        interfaces.enp0s25br.useDHCP = true;

        #bridges."intern".interfaces = [];
        #interfaces."intern" = {
        #    ip4 = [ {
        #        address = "10.0.1.100";
        #        prefixLength = 24;
        #    } ];
        #};

        #nat = {
        #    enable = true;
        #    externalInterface = "enp0s25";
        #    internalIPs = [ "10.0.1.0/24" ];
        #    internalInterfaces = [ "intern" ];
        #};
    };
}
