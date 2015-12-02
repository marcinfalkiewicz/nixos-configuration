
{ config, pkgs, ... }:

{
    ## samba settings

    services.samba = {
        enable = true;
        invalidUsers = [ "root" ];
        extraConfig = "
            workgroup = NIXOS

            server string = KATAMARI
            server role = auto
        ";
        syncPasswordsByPam = true;

        shares = {
            torrents = {
                comment = "Torrents";
                path = "/zstorage/torrents";
                "valid user" = "marcinf";
                public = false;
                writable = true;
            };
            iso = {
                comment = "ISO Images";
                path    = "/zstorage/iso";
                "valid user" = "marcinf";
                public = false;
                "read only" = true;
            };
        };
    };
}
