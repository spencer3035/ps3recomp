{
  description = "Development shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
  };

  outputs = { self, nixpkgs, flake-utils, pyproject-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python3;

        # Load/parse requirements.txt
        project = pyproject-nix.lib.project.loadRequirementsTxt {
          projectRoot = ./.;
        };

        pythonEnv =
          # Assert that versions from nixpkgs match what's described in requirements.txt
          # In projects that are overly strict about pinning it might be best to remove this assertion entirely.
          assert project.validators.validateVersionConstraints { inherit python; } == { };
          (
            # Render requirements.txt into a Python withPackages environment
            python.withPackages (
              project.renderers.withPackages { inherit python; }
            )
          );
      in
      {
        devShells.default = pkgs.mkShell {
          name = "Development shell";
          # Cli tools needed for dev
          packages = with pkgs; [ gdb lldb gcc cmake ninja pythonEnv SDL2 ];
        };
      }
    );
}
