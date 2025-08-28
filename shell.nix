{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  name = "devenv";

  buildInputs = with pkgs; [
    clang-tools
    gcc
    nasm
    gnumake
  ];
}
