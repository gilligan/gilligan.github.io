with (import <nixpkgs> {});
let
  env = bundlerEnv {
    name = "tblog-bundler-env";
    inherit ruby;
    gemfile  = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset   = ./gemset.nix;
  };
in stdenv.mkDerivation {
  name = "tblog";
  buildInputs = [ env ];
  shellHook = ''
      #jekyll serve --watch --future
      #exit 0
  '';
}
