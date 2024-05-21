{
  description = "packer build environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in
   {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        packer
      ];
    };
  };
}
