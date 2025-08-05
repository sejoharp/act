{
  description = "Rust example flake for Zero to Nix";

  inputs = {
    # Latest stable Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # A helper library for Rust + Nix
    rust-overlay.url = "https://flakehub.com/f/oxalica/rust-overlay/*";
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      pkgs = import <nixpkgs> { };
      manifest = (nixpkgs.lib.importTOML ./Cargo.toml).package;

      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs allSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              overlays = [
                # Provides Nixpkgs with a rust-bin attribute for building Rust toolchains
                rust-overlay.overlays.default
                # Uses the rust-bin attribute to select a Rust toolchain
                self.overlays.default
              ];
            };
          }
        );
    in
    {
      overlays.default = final: prev: {
        # The Rust toolchain used for the package build
        rustToolchain = final.rust-bin.stable.latest.default;
      };

      packages = forAllSystems (
        { pkgs }:
        {
          default =
            let
              rustPlatform = pkgs.makeRustPlatform {
                cargo = pkgs.rustToolchain;
                rustc = pkgs.rustToolchain;
              };
              getCommitCount =
                pkgs:
                pkgs.runCommand "get-commit-count"
                  {
                    buildInputs = [ pkgs.git pkgs.curl ];
                  }
                  ''
                    COMMIT_COUNT=$(curl -s -I -k "https://api.github.com/repos/sejoharp/act/commits?per_page=1" | sed -n '/^[Ll]ink:/ s/.*"next".*page=\([0-9]*\).*"last".*/\1/p')
                    printf "%s.0.0" "$COMMIT_COUNT" > $out
                  '';
              commitCountFile = getCommitCount pkgs;
              dynamicVersion = builtins.replaceStrings [ "\n" " " "\t" ] [ "" "" "" ] (
                builtins.readFile commitCountFile
              );

            in
            rustPlatform.buildRustPackage {
              name = manifest.name;
              version = dynamicVersion;
              src = pkgs.lib.cleanSource ./.;
              cargoLock = {
                lockFile = ./Cargo.lock;
              };
              preBuild = ''
                # bash
                echo "current directory content: $(ls -halt)"
                echo "Setting version to: ${dynamicVersion}"
                sed -i 's/^version = ".*"/version = "${dynamicVersion}"/' Cargo.toml
                echo "Updated Cargo.toml:"
                grep '^version = ' Cargo.toml
              '';
            };
        }
      );
    };
}
