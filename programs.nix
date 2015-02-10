{ config, pkgs, ... }:

{
  programs.bash.enableCompletion = true;

  programs.nano.nanorc =
    ''
    set nowrap
    set tabstospaces
    set tabsize 2
    '';
}
