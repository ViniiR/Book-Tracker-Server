{
    inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    outputs = {
        self,
        nixpkgs,
    }: let
        system = "x86_64-linux";
        pkgs = import nixpkgs {inherit system;};
        lib = pkgs.lib;
    in {
        devShells.${system}.default = pkgs.mkShell rec {
            NIX_ENFORCE_PURITY = 0;
            LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;

            # Packages available in the User's shell
            packages = with pkgs; [
                zsh
                opam
                ocamlPackages.ocaml-lsp
                ocamlPackages.ocamlformat
                ocamlPackages.dune_3
            ];

            # Packages necessary to only Build the project
            nativeBuildInputs = with pkgs; [
            ];

            # Packages necessary for Running the Built program and or Building
            buildInputs = with pkgs; [
                ocaml
                ocamlPackages.dream
                ocamlPackages.dream-pure
                ocamlPackages.findlib
                ocamlPackages.postgresql
            ];

            shellHook = ''
                export SHELL=${pkgs.zsh}/bin/zsh
                exec zsh;
            '';
        };
    };
}
