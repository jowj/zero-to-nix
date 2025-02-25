{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    }:

    let
      # Conveniences for Nixpkgs
      overlays = [
        (self: super: {
          nodejs = super.nodejs-18_x;
          pnpm = super.nodePackages.pnpm;
          alex = super.nodePackages.alex;
        })
      ];

      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });

      # Helper function for scripting
      runPkg = pkgs: pkg: "${pkgs.${pkg}}/bin/${pkg}";
    in
    {
      devShells = forAllSystems
        ({ pkgs }:
          let
            common = with pkgs; [
              # CI
              cachix
              direnv
              nix-direnv

              # Language
              vale
              alex

              # Link checking
              htmltest

              # JS
              nodejs
              pnpm
            ];

            run = pkg: runPkg pkgs pkg;

            scripts = with pkgs; [
              (writeScriptBin "clean" ''
                rm -rf dist
              '')

              (writeScriptBin "setup" ''
                clean
                ${run "pnpm"} install
              '')

              (writeScriptBin "build" ''
                setup
                ${run "pnpm"} run build
              '')

              (writeScriptBin "build-ci" ''
                setup
                ENV=ci ${run "pnpm"} run build
              '')

              (writeScriptBin "dev" ''
                setup
                ${run "pnpm"} run dev
              '')

              (writeScriptBin "format" ''
                setup
                ${run "pnpm"} run format
              '')

              (writeScriptBin "check-internal-links" ''
                ${run "htmltest"} --conf ./.htmltest.internal.yml
              '')

              (writeScriptBin "check-external-links" ''
                ${run "htmltest"} --conf ./.htmltest.external.yml
              '')

              (writeScriptBin "lint-style" ''
                ${run "vale"} src/pages
              '')

              (writeScriptBin "check-sensitivity" ''
                ${run "alex"} --quiet src/pages
              '')

              (writeScriptBin "check-types" ''
                ${run "pnpm"} run typecheck
              '')

              (writeScriptBin "preview" ''
                build
                ${run "pnpm"} run preview
              '')

              # Run this to see if CI will pass
              (writeScriptBin "ci" ''
                set -e
                build-ci
                check-internal-links
                lint-style
                check-sensitivity
                check-types
              '')
            ];

            exampleShells = import ./nix/shell/example.nix { inherit pkgs; };
          in
          {
            inherit (exampleShells) example cpp haskell hook javascript python go rust multi;
          } // {
            default = pkgs.mkShell
              {
                packages = common ++ scripts;
              };
          });

      apps = forAllSystems ({ pkgs }:
        let
          run = pkg: runPkg pkgs pkg;

          runLocal = pkgs.writeScriptBin "run-local" ''
            rm -rf dist
            ${run "pnpm"} install
            ${run "pnpm"} run build
            ${run "pnpm"} run preview
          '';
        in
        {
          default = {
            type = "app";
            program = "${runLocal}/bin/run-local";
          };
        });

      templates = {
        cpp-dev = {
          path = ./nix/templates/dev/cpp;
          description = "C++ dev environment template for Zero to Nix";
        };

        go-dev = {
          path = ./nix/templates/dev/go;
          description = "Go dev environment template for Zero to Nix";
        };

        haskell-dev = {
          path = ./nix/templates/dev/haskell;
          description = "Haskell dev environment template for Zero to Nix";
        };

        javascript-dev = {
          path = ./nix/templates/dev/javascript;
          description = "JavaScript dev environment template for Zero to Nix";
        };

        python-dev = {
          path = ./nix/templates/dev/python;
          description = "Python dev environment template for Zero to Nix";
        };

        rust-dev = {
          path = ./nix/templates/dev/rust;
          description = "Rust dev environment template for Zero to Nix";
        };

        cpp-pkg = {
          path = ./nix/templates/pkg/cpp;
          description = "C++ package starter template for Zero to Nix";
        };

        go-pkg = {
          path = ./nix/templates/pkg/go;
          description = "Go package starter template for Zero to Nix";
        };

        haskell-pkg = {
          path = ./nix/templates/pkg/haskell;
          description = "Haskell package starter template for Zero to Nix";
        };

        javascript-pkg = {
          path = ./nix/templates/pkg/javascript;
          description = "JavaScript package starter template for Zero to Nix";
        };

        python-pkg = {
          path = ./nix/templates/pkg/python;
          description = "Python package starter template for Zero to Nix";
        };

        rust-pkg = {
          path = ./nix/templates/pkg/rust;
          description = "Rust package starter template for Zero to Nix";
        };
      };
    };
}
