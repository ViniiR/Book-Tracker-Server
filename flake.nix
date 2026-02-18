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
        # Will be built by docker image
        packages.${system}.default = pkgs.ocamlPackages.buildDunePackage {
            pname = "server";
            version = "0.1";
            src = ./.;

            duneVersion = "3";

            nativeBuildInputs = with pkgs.ocamlPackages; [
                ocaml
                dune_3
                findlib
                dream
            ];
            buildInputs = with pkgs.ocamlPackages; [
                dream
                dream-pure
                lwt
                lwt_ppx
                caqti
                caqti-lwt
                caqti-async
                caqti-driver-postgresql
                yojson
                alcotest
            ];
        };

        devShells.${system}.default = pkgs.mkShell rec {
            NIX_ENFORCE_PURITY = 0;
            LD_LIBRARY_PATH = lib.makeLibraryPath packages;

            # Dev environment variables
            PGSQL_CONNECTION = "postgresql://main:development@localhost:5432/main";
            AUTH_USERNAME = "dev";
            AUTH_PASSWORD = "developmentpassword";
            RUN_HOST = "127.0.0.1";
            PORT = "5001";

            # Packages
            packages = with pkgs; [
                # Libs
                ocamlPackages.dream
                ocamlPackages.dream-pure
                ocamlPackages.lwt
                ocamlPackages.lwt_ppx
                ocamlPackages.caqti
                ocamlPackages.caqti-lwt
                ocamlPackages.caqti-async
                ocamlPackages.caqti-driver-postgresql
                ocamlPackages.yojson
                ocamlPackages.alcotest

                # Shell packages
                zsh
                opam

                # Build packages
                ocaml
                ocamlPackages.ocaml-lsp
                ocamlPackages.ocamlformat
                ocamlPackages.dune_3
                ocamlPackages.findlib
            ];

            shellHook = ''
                export SHELL=${pkgs.zsh}/bin/zsh
                exec zsh;
            '';
        };
    };
}
