{
  description = "Development environment for trezor-app-devkit";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/a07d4ce6bee67d7c838a8a5796e75dff9caa21ef";
    rust-overlay = {
      url = "github:oxalica/rust-overlay/f600ea449c7b5bb596fa1cf21c871cc5b9e31316";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rustNightly = pkgs.rust-bin.nightly."2026-02-26".minimal.override {
          targets = [
            "thumbv8m.main-none-eabihf"
          ];
          extensions = [ "rust-src" "clippy" "rustfmt" "llvm-tools-preview" ];
        };

        rustSrc = pkgs.rust-bin.nightly."2026-02-26".rust-src;

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustNightly;
          rustc = rustNightly;
        };

        appCreate = pkgs.writeShellScriptBin "app-create" ''
          template=${self}/template
          ${builtins.readFile ./app-create.sh}
        '';

        # trezor-app-tool from crates.io, for apps generated without
        # TREZOR_FIRMWARE. Not published yet, so the hashes are placeholders
        # and the package is built only when requested by app-tool. After
        # publishing, build it once and copy the real hashes from the errors.
        trezorAppTool = rustPlatform.buildRustPackage rec {
          pname = "trezor-app-tool";
          version = "0.1.0";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = pkgs.lib.fakeHash;
          };
          cargoHash = pkgs.lib.fakeHash;
        };

        appTool = pkgs.writeShellScriptBin "app-tool" ''
          devkit=${self}
          system=${system}
          trezor_firmware_resolver=${./firmware-path.py}
          ${builtins.readFile ./app-tool.sh}
        '';

        # Dev shell for generated apps (used by the template's flake.nix).
        appShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustNightly
            appTool
            cargo-binutils
            pkgsCross.arm-embedded.buildPackages.binutils
            llvmPackages.clang
            llvmPackages.llvm
            python3
            uv
            protobuf
            pyright
            pkg-config
            openssl
            zlib
            libffi
            libusb1
            libjpeg
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.libffi
            pkgs.libjpeg
            pkgs.libusb1
            pkgs.libressl
          ];
          DYLD_LIBRARY_PATH = "${pkgs.libffi}/lib:${pkgs.libjpeg.out}/lib:${pkgs.libusb1}/lib:${pkgs.libressl.out}/lib";
          LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
          RUST_SRC_PATH = "${rustSrc}/lib/rustlib/src/rust/library";

        };
      in
      {
        packages.trezor-app-tool =
          let
            trezor_firmware = builtins.getEnv "TREZOR_FIRMWARE";
            src = pkgs.lib.cleanSourceWith {
              src = pkgs.lib.cleanSource
                (builtins.toPath "${trezor_firmware}/sdk/crates/trezor-app-tool");
              filter = path: type: builtins.baseNameOf path != "target";
              name = "trezor-app-tool-source";
            };
          in
          if trezor_firmware == "" then trezorAppTool else
            rustPlatform.buildRustPackage {
              pname = "trezor-app-tool";
              version = (builtins.fromTOML
                (builtins.readFile "${src}/Cargo.toml")).package.version;
              inherit src;
              cargoLock.lockFile = "${src}/Cargo.lock";
            };

        devShells.app = appShell;

        # The app shell plus the template generator.
        devShells.default = appShell.overrideAttrs (old: {
          buildInputs = old.buildInputs ++ [
            pkgs.cargo-generate
            appCreate
          ];
          # Keep caller-provided checkout paths valid after changing directories.
          shellHook = ''
            if [ -n "''${TREZOR_FIRMWARE:-}" ]; then
              export TREZOR_FIRMWARE="$(realpath "$TREZOR_FIRMWARE")"
            fi
            if [ -n "''${TREZOR_APP_DEVKIT:-}" ]; then
              export TREZOR_APP_DEVKIT="$(realpath "$TREZOR_APP_DEVKIT")"
            fi
          '';
        });
      });
}