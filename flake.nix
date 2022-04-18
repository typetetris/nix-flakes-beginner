{
	inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
	inputs.nix.url = "github:nixos/nix/master";
	inputs.flake-utils.url = "github:numtide/flake-utils";
	inputs.flake-compat.url = "github:edolstra/flake-compat";
	inputs.flake-compat.flake = false;

	outputs = {self, flake-utils, nixpkgs, nix, flake-compat, ...}: 
	flake-utils.lib.eachDefaultSystem (system:
	let
		pkgs = nixpkgs.legacyPackages.${system};		
		wrappedNix = pkgs.runCommand "nix" {
			nativeBuildInputs = [
				pkgs.makeWrapper
			];
		} ''
		mkdir -p $out/bin
		makeWrapper ${nix.packages.${system}.nix}/bin/nix $out/bin/nix --add-flags '--extra-experimental-features "flakes nix-command"'
		'';
	in
	{
		devShells = {
			default = pkgs.mkShell {
				packages = [wrappedNix];
			};
		};
		devShell = self.devShells.${system}.default;
	});
}
