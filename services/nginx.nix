#
{ config, pkgs, ... }:

let
    nginxConfig = pkgs.writeText "nginx-servers.conf" ''
        server {
            listen 127.0.0.1:80;

            root /var/www;
            index index.html;
        }
    '';
in
{
    services.nginx = {
        enable = true;
        httpConfig = ''
            include ${nginxConfig};
        '';
    };
}
