{
  description = "Development environment for a Trezor app";

  inputs = {
{%- if devkit_path %}
    trezor-app-devkit.url = "git+file://{{devkit_path}}";
{%- else %}
    trezor-app-devkit.url = "github:cepetr/trezor-app-devkit";
{%- endif %}
    # Also used by `nix develop` for the interactive bash.
    nixpkgs.follows = "trezor-app-devkit/nixpkgs";
  };

  outputs = { trezor-app-devkit, ... }:
    trezor-app-devkit.inputs.flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = trezor-app-devkit.devShells.${system}.app;
    });
}
