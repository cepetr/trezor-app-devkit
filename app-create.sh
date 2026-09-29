# Generate an app from the template supplied by flake.nix and initialize Git.
# Stage the generated files before locking the flake so Nix can see them;
# stage the resulting lock file separately before the initial commit.

set -eu

if [ "$#" -eq 0 ]; then
  echo "Usage: app-create <project-name> [cargo-generate options]" >&2
  exit 1
fi
name="$1"
shift
if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  echo "app-create: project name must start with a letter and contain only letters, digits, hyphens, or underscores" >&2
  exit 1
fi
dest="$PWD/$name"
if [ -e "$dest" ] || [ -L "$dest" ]; then
  echo "app-create: $dest already exists" >&2
  exit 1
fi

# The Nix store is read-only and cargo-generate keeps file permissions,
# so render from a writable copy of the template.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp -r "$template" "$tmp/template"
chmod -R u+w "$tmp"

# Point the generated app at a local trezor-firmware checkout
# (unpublished SDK crates and trezor-app-tool).
if [ -n "${TREZOR_FIRMWARE:-}" ]; then
  set -- -d firmware_path="$(realpath "$TREZOR_FIRMWARE")" "$@"
fi

# Point the generated app's flake at a local trezor-app-devkit
# checkout instead of GitHub.
if [ -n "${TREZOR_APP_DEVKIT:-}" ]; then
  set -- -d devkit_path="$(realpath "$TREZOR_APP_DEVKIT")" "$@"
fi

cargo generate \
  --path "$tmp/template" \
  --destination "$PWD" \
  --name "$name" \
  --force \
  --vcs none \
  "$@"

# Nix flakes only see git-tracked files, so commit everything.
git -C "$dest" init --quiet --initial-branch=main
git -C "$dest" add -A

# Pin the app to the current trezor-app-devkit version. Skipped
# when the tooling is a local checkout with uncommitted changes;
# the app then follows the working tree.
if ! log=$(cd "$dest" && nix flake lock 2>&1); then
  case "$log" in
    *"has an unlocked input"*) ;;
    *) echo "$log" >&2; exit 1 ;;
  esac
fi
if [ -f "$dest/flake.lock" ]; then
  git -C "$dest" add flake.lock
fi

git -C "$dest" commit --quiet -m "initial commit"
echo "Created $dest"
