
{ config, pkgs, ... }:

{
    services.ntp.enable = true;
    services.irqbalance.enable = true;
    services.haveged.enable = true;

    systemd.services.irqbalance.environment = { IRQBALANCE_BANNED_CPUS = "F0"; };
}
