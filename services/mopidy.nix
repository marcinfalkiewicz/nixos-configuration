
{ config, pkgs, ... }:

{
  services.mopidy = {
      enable = false;
      extensionPackages = [
          pkgs.mopidy-spotify
          pkgs.mopidy-mopify
      ];
  };
}
