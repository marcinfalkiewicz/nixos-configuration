
{ config, pkgs, ... }:

{
    services.ntp.enable = true;
    services.irqbalance.enable = true;
}
