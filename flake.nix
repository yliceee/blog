{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.x86_64-linux.default =
        pkgs.mkShell { packages = with pkgs; [ pkgs.hugo pkgs.go ]; };
    };
}
