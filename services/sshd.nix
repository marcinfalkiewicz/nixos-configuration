
{ config, pkgs, ... }:

{
  services.openssh = {
      enable = true;
      ports = [ 2538 ];
      listenAddresses = [ { addr = "0.0.0.0"; port = 2538; } ];
      permitRootLogin = "no";
      forwardX11 = true;
  };

}
