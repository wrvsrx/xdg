{
  description = "flake template";

  inputs = {
    nur-wrvsrx.url = "github:wrvsrx/nur-packages";
    nixpkgs.follows = "nur-wrvsrx/nixpkgs";
    flake-parts.follows = "nur-wrvsrx/flake-parts";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { inputs, ... }:
      {
        systems = [ "x86_64-linux" ];
        perSystem =
          { pkgs, system, ... }:
          rec {
            _module.args.pkgs = import inputs.nixpkgs {
              overlays = [ inputs.nur-wrvsrx.overlays.default ];
              inherit system;
            };
            packages.default = pkgs.leanPackages.callPackage ./default.nix { };
            devShells.default = pkgs.mkShell { inputsFrom = [ packages.default ]; };
            formatter = pkgs.nixfmt;
          };
      }
    );
}
