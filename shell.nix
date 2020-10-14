{ pkgs ? import ./nix {} }:

let
  inherit (pkgs) ruby bundlerEnv stdenv;

  env = bundlerEnv {
    name = "blog-env";
    inherit ruby;
    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
  };
in
  stdenv.mkDerivation {
    name = "tblog";
    buildInputs = [ env ];
    shellHook = ''
      jekyll serve --watch --future
      exit 0
    '';
  }
