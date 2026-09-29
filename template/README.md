# Trezor App

This is a simple Trezor app created from a template.

When using a local firmware checkout, keep it available at the path used when
generating the app.

Enter the development environment:

```sh
nix develop
```

Build the app for hardware:

```sh
app-tool build --arch armv8m
```

Or build it for the emulator:

```sh
app-tool build -e
```