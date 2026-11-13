# Trezor App Devkit

This repository provides a development environment for building, debugging, and testing external applications for Trezor hardware wallets.

It also includes an application template and a tool to generate a new app repository from that template.

## How to start

1. Install [Nix](https://nixos.org/download/) and enable the `nix-command` and `flakes` experimental features in your Nix configuration:

   ```ini
   experimental-features = nix-command flakes
   ```

2. Generate a new app repository using the development shell directly from GitHub, without needing a local devkit checkout:

   ```sh
   nix develop github:cepetr/trezor-app-devkit --command app-create my-app
   ```

Pass the project folder name as the first argument. The generator prompts for an application ID, display name, and vendor, creates the folder in the current directory, and initializes a Git repository with an initial commit.

**Current limitation:** building still requires a local firmware checkout because the SDK crates and `trezor-app-tool` are not yet published on crates.io. Before generating an app you intend to build, follow
[Use a local firmware checkout](#use-a-local-firmware-checkout) below. To also use a local devkit folder, see
[Use a local devkit checkout](#use-a-local-devkit-checkout).

## Build the app

For an app named `my-app`, enter its development shell and build for hardware:

```sh
cd my-app
nix develop
app-tool build --arch armv8m
```

Or build for the emulator:

```sh
app-tool build --emulator
```

## Use a local firmware checkout

If you have a `trezor-firmware` checkout containing the `sdk/crates` directory, set `TREZOR_FIRMWARE` for the development shell before generating the app:

```sh
TREZOR_FIRMWARE=/absolute/path/to/trezor-firmware \
  nix develop github:cepetr/trezor-app-devkit --command app-create my-app
```

Keep the firmware checkout available at the same path when building the app.

## Use a local devkit checkout

When developing the devkit, set `TREZOR_APP_DEVKIT` for the generator to configure the generated app to use your local checkout rather than the GitHub repository:

```sh
TREZOR_FIRMWARE=/absolute/path/to/trezor-firmware \
  TREZOR_APP_DEVKIT=/absolute/path/to/trezor-app-devkit \
  nix develop /absolute/path/to/trezor-app-devkit --command app-create my-app
```

`TREZOR_APP_DEVKIT` selects the devkit input written to the generated app's `flake.nix`; it is not a runtime override for an already generated app. Set both variables before generation so the app uses your local firmware and devkit checkouts.
