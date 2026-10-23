{
  description = "Suwayomi-Server: manga reader server that runs Mihon (Tachiyomi) extensions (Suwayomi/Suwayomi-Server).";

  inputs = {
    flake-lib.url = "github:jgus-org/flake-lib/v1";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    {
      self,
      flake-lib,
      nixpkgs,
    }:
    let
      pin = import ./pin.nix;
      inherit (pin) version;
      source = {
        asset = "Suwayomi-Server-v\${version}.jar";
        owner = "Suwayomi";
        repo = "Suwayomi-Server";
        type = "github-release-asset";
      };
    in
    flake-lib.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        orgFormatting = flake-lib.lib.mkFormatting {
          inherit self system;
        };
        jdk = flake-lib.lib.warnIfNewerMajor {
          inherit pkgs;
          name = "jdk25_headless";
        };

        src = pkgs.fetchurl {
          hash = pin.hash or "";
          url = "https://github.com/${source.owner}/${source.repo}/releases/download/v${version}/Suwayomi-Server-v${version}.jar";
        };

        suwayomi-server = pkgs.stdenvNoCC.mkDerivation {
          inherit src version;
          buildPhase = ''
            runHook preBuild

            makeWrapper ${jdk}/bin/java $out/bin/tachidesk-server \
              --add-flags "-Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false -jar $src"

            runHook postBuild
          '';
          dontUnpack = true;
          meta = {
            description = "Free and open source manga reader server that runs extensions built for Mihon (Tachiyomi)";
            homepage = "https://github.com/Suwayomi/Suwayomi-Server";
            license = pkgs.lib.licenses.mpl20;
            mainProgram = "tachidesk-server";
            platforms = jdk.meta.platforms;
          };
          nativeBuildInputs = [ pkgs.makeWrapper ];
          pname = "suwayomi-server";
        };
      in
      {
        checks.formatting = orgFormatting.check;
        formatter = orgFormatting.formatter;
        packages = {
          inherit suwayomi-server;
          default = suwayomi-server;
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            minimumTrackingVersion = "2.2.2100";
            pinSchema = "github-asset";
          };
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
          };
        };
      }
    );
}
