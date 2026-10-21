# suwayomi-server-flake

A Nix flake that packages [Suwayomi-Server](https://github.com/Suwayomi/Suwayomi-Server), a manga reader server that runs extensions built for Mihon (Tachiyomi), from upstream's released jar.

## Outputs

For `x86_64-linux`, `aarch64-linux`, and `aarch64-darwin`:

- `packages.<system>.suwayomi-server` — upstream's `Suwayomi-Server-v<version>.jar` plus a `tachidesk-server` launcher. `packages.<system>.default` is the same derivation.
- `packages.<system>.update-version` and `packages.<system>.update-branches` — maintenance outputs that move the pinned release. Neither is needed to consume the flake.
- `formatter` and `checks.formatting`.

There are no overlays, NixOS modules, devShells, or apps: take the package and wire it into a service, image, or profile yourself. The pinned release version and the jar's hash live in `pin.nix`.

## Consuming it

```nix
inputs.suwayomi-server = {
  url = "github:jgus-org/suwayomi-server-flake";
  inputs.nixpkgs.follows = "nixpkgs";
  inputs.flake-lib.follows = "flake-lib";
};
```

then install `inputs.suwayomi-server.packages.${system}.suwayomi-server`. The executable is `tachidesk-server` — upstream's historical launcher name — and `meta.mainProgram` names it, so `nix run github:jgus-org/suwayomi-server-flake` starts the server in the foreground.

Following `nixpkgs` is safe: the only hash in `pin.nix` is the release jar's own content hash, which does not depend on the package set the build runs against. It does mean the JDK is resolved from your package set, so `jdk25_headless` has to exist there. There is no `flake-utils` input.

## Runtime

This flake tracks the portable jar asset, not upstream's per-platform bundles, so the Java runtime comes from Nix rather than from the artifact. The launcher invokes `java` from nixpkgs' `jdk25_headless`, and `meta.platforms` is that JDK's platform set. Upstream compiles to a Java 21 bytecode target and carries optional `META-INF/versions/23` and `META-INF/versions/25` class trees alongside it; Java 25 is upstream's own build-and-bundle runtime rather than a floor this package enforces.

The server is a long-lived HTTP server. It writes its database, downloaded chapters, and installed extensions to a data directory on first start; point it wherever you want with the `server.rootDir` setting.

**JVM options go in through the environment, not the command line.** The launcher puts every argument it is given after `-jar <jar>`, so arguments reach Suwayomi rather than the JVM. Set JVM system properties through `JAVA_TOOL_OPTIONS`, prefixing each key with `suwayomi.tachidesk.config.`:

```bash
JAVA_TOOL_OPTIONS="-Dsuwayomi.tachidesk.config.server.rootDir=/config -Dsuwayomi.tachidesk.config.server.ip=[::]" tachidesk-server
```

**One property is fixed by the launcher.** It passes `-Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false` before `-jar`, and a command-line `-D` takes precedence over the same key supplied through `JAVA_TOOL_OPTIONS`, so that key cannot be changed from the environment. Everything else is left at upstream's default.

## License

`meta.license` is [MPL-2.0](https://www.mozilla.org/en-US/MPL/2.0/), upstream's own license. The package installs upstream's release jar unmodified and adds only the launcher, so it adds no license obligation of its own; extensions you install at run time carry their own licenses.
