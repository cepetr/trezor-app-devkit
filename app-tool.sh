set -euo pipefail

# Cargo does not apply [env] to standalone commands. Query its
# merged configuration using the dev shell's nightly toolchain.
trezor_firmware=$(cargo -Z unstable-options config get --format json | python3 "$trezor_firmware_resolver")

if [ -n "$trezor_firmware" ]; then
  tool=$(
    TREZOR_FIRMWARE="$trezor_firmware" nix build \
      --impure \
      --no-link \
      --no-write-lock-file \
      --print-out-paths \
      "$devkit#trezor-app-tool"
  )
else
  # Cache a Nix GC root per platform and devkit source so published builds skip
  # evaluation on later runs. Local builds above still check for source changes.
  tool="${XDG_CACHE_HOME:-$HOME/.cache}/trezor-app-devkit/$system/${devkit##*/}"
  if [ ! -x "$tool/bin/trezor-app-tool" ]; then
    mkdir -p "${tool%/*}"
    TREZOR_FIRMWARE="" nix build \
      --impure \
      --no-write-lock-file \
      --out-link "$tool" \
      "$devkit#trezor-app-tool"
  fi
fi

exec "$tool/bin/trezor-app-tool" "$@"
