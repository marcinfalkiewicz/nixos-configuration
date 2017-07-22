# vim: ft=nix

{ config, pkgs, ... }:

let
  nginxConfig = pkgs.writeText "nginx-servers.conf" ''

upstream netdata {
  server 127.0.0.1:19999;
  keepalive 64;
}

server {
  listen 80;

  location ~ ^/munin(.*)$ {
    alias /var/www/munin$1;
    index index.html;
  }

  location /ytp {
    alias /var/www/ytp;
    index index.html;
  }

  location /netdata {
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Connection "Keep-Alive";
    proxy_set_header Proxy-Connection "Keep-Alive";

    proxy_pass_request_headers on;
    proxy_store off;

    proxy_buffering off;
    proxy_buffer_size 4k;

    proxy_pass http://netdata/;
    proxy_http_version 1.1;

  }

}

'';

in
{
  services.nginx = {
    enable = false;
    httpConfig = ''
      include ${nginxConfig};
    '';
  };
  services.clamav = {
    daemon.enable = true;
    updater.enable = true;
    updater.frequency = 7;
  };

  virtualisation.libvirtd = {
    enable = true;
    enableKVM = true;
    qemuVerbatimConfig = ''
      namespaces = []
      security_driver = "none"
    '';
  };

  services.ntp.enable = false;

  systemd.services.irqbalance.environment = { IRQBALANCE_BANNED_CPUS = "F0"; };
  services.irqbalance.enable = true;

  services.haveged.enable = true;
  services.nix-serve.enable = false;
  services.gpm.enable = false;

  services.munin-node.enable = false;
  services.munin-cron = {
    enable = false;
    hosts = ''
      [${config.networking.hostName}]
      address localhost
    '';
  };

  #services.netdata = {
  #  enable = false;
  #  configFile = ''
  #    [global]
  #    run as user = root
  #      web files owner = root
  #      cache directory = /var/cache/netdata
  #      log directory = /var/log/netdata
  #      debug log = /var/log/netdata/debug.log
  #      error log = /var/log/netdata/error.log
  #      access log = /var/log/netdata/access.log
  #      memory deduplication (ksm) = no

  #      [plugin:proc]
  #      /proc/net/ip_vs/stats = no
  #        /proc/net/rpc/nfsd = no
  #        /sys/kernel/mm/ksm = no

  #        '';
  #};

  services.mopidy = {
    enable = false;
    extensionPackages = [
      pkgs.mopidy-spotify
      pkgs.mopidy-mopify
    ];
  };
  services.samba = {
    enable = true;
    invalidUsers = [ "root" ];
    extraConfig = "
      workgroup = NIXOS

      server string = KATAMARI
      server role = auto

      socket options = TCP_NODELAY
    ";
    syncPasswordsByPam = true;

    shares = {
      torrents = {
        comment = "Torrents";
        path = "/mnt/raid/torrents";
        "valid users" = "dweller @transmission";
        public = false;
        writable = true;
      };
      iso = {
        comment = "ISO Images";
        path  = "/mnt/raid/iso";
        "valid users" = "dweller";
        public = false;
        "read only" = true;
      };
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 2538 ];
    listenAddresses = [
      { addr = "0.0.0.0"; port = 2538; }
    ];
    permitRootLogin = "no";
    forwardX11 = false;
  };

  services.syncthing = {
    enable = false;
    useInotify = false;
    dataDir = "/mnt/raid/backups/syncthing";
  };
  systemd.services.syncthing.serviceConfig = {
    CPUAccounting = true;
    CPUQuota = "15%";
  };

  systemd.services.transmission.wantedBy = [];
  services.transmission = {
    enable = true;
    port = 9091;
    settings = {
      download-dir = "/mnt/raid/torrents";
      incomplete-dir = "/mnt/raid/torrents/.incomplete";
      incomplete-dir-enabled = true;
      watch-dir = "/mnt/raid/torrents/.torrentfiles";
      watch-dir-enabled = true;

      rpc-whitelist = "127.0.0.1,192.168.1.100";
      umask = 022; # for users in group "transmission" to have access to torrents

      peer-limit-global = 750;
      peer-limit-per-torrent = 75;
      peer-port = 60450;

      alt-speed-time-enabled = true;
      alt-speed-time-begin = 60;
      alt-speed-time-end = 720;
      alt-speed-up = 256;
      alt-speed-down = 5120;

      speed-limit-up-enabled = true;
      speed-limit-down = 3072;
      speed-limit-up = 100;

      upload-slots-per-torrent = 5;

      preallocation = 1;

      dht-enabled = true;
      encryption = 2;
      encryption-required = true;
    };
  };

  systemd.services.zfs-mount.wantedBy = [ "local-fs.target" ];
  systemd.services.zfs-mount.requires = [ "zfs-import.target" ];
}
