{
  withHoogle ? true
  , static ? false
  , pname ? "bank-simulation"
}:
let
  inherit (import <nixpkgs> {}) fetchFromGitHub;

  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/19.09.tar.gz";
    sha256 = "0mhqhq21y5vrr1f30qd2bvydv4bbbslvyzclhw0kdxmkgg3z4c92";
  };

  staticAttrs = {
    enableSharedExecutables = false;
    enableSharedLibraries = false;
    configureFlags = [
      "--ghc-option=-optl=-static"
      "--ghc-option=-optl=-pthread"
      "--ghc-option=-optl=-L${pkgs.gmp6.override { withStatic = true; }}/lib"
      "--ghc-option=-optl=-L${pkgs.zlib.static}/lib"
      "--extra-lib-dirs=${pkgs.libffi.overrideAttrs (old: { dontDisableStatic = true; })}/lib"
    ];
  };

  config = {
    packageOverrides = pkgs: rec {
      haskellPackages = pkgs.haskellPackages.override {
        overrides = self: super: rec {
          ghc = super.ghc // { withPackages = if withHoogle then super.ghc.withHoogle else super.ghc ; };

          ghcWithPackages = self.ghc.withPackages;

          bank-simulation = self.callCabal2nix "bank-simulation" (pkgs.lib.cleanSource ./.) { };

        };
      };
    };
  };

  pkgs =
    if static
    then (import nixpkgs { inherit config; }).pkgsMusl
    else import nixpkgs { inherit config; };
  drv = pkgs.haskellPackages.bank-simulation;
in
  if pkgs.lib.inNixShell
    then
      drv.env.overrideAttrs(attrs:
        { buildInputs =
          with pkgs.haskellPackages;
          [
            cabal-install
            cabal2nix
            ghcid
            hindent
            hlint
            stylish-haskell
          ] ++ [
            zlib
          ] ++ attrs.buildInputs;
        })
        else drv.overrideAttrs(attrs:
        {
          buildInputs = attrs.buildInputs ++ [ pkgs.zlib ];
        })
