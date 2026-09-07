{
  description = "Suwayomi-Server: manga reader server that runs Mihon (Tachiyomi) extensions (Suwayomi/Suwayomi-Server).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus-org/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-lib }:
    let
      pin = import ./pin.nix;
      inherit (pin) version;
      source = {
        type = "github-release-asset";
        owner = "Suwayomi";
        repo = "Suwayomi-Server";
        asset = "Suwayomi-Server-v\${version}.jar";
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        jdk = flake-lib.lib.warnIfNewerMajor { inherit pkgs; name = "jdk25_headless"; };

        src = pkgs.fetchurl {
          url = "https://github.com/${source.owner}/${source.repo}/releases/download/v${version}/Suwayomi-Server-v${version}.jar";
          hash = pin.hash or "";
        };

        suwayomi-server = pkgs.stdenvNoCC.mkDerivation {
          pname = "suwayomi-server";
          inherit version src;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontUnpack = true;

          buildPhase = ''
            runHook preBuild

            makeWrapper ${jdk}/bin/java $out/bin/tachidesk-server \
              --add-flags "-Dsuwayomi.tachidesk.config.server.initialOpenInBrowserEnabled=false -jar $src"

            runHook postBuild
          '';

          meta = {
            description = "Free and open source manga reader server that runs extensions built for Mihon (Tachiyomi)";
            homepage = "https://github.com/Suwayomi/Suwayomi-Server";
            license = pkgs.lib.licenses.mpl20;
            platforms = jdk.meta.platforms;
            mainProgram = "tachidesk-server";
          };
        };
      in
      {
        packages = {
          inherit suwayomi-server;
          default = suwayomi-server;
          update-version = flake-lib.lib.mkUpdateVersion {
            inherit pkgs source;
            buildAttr = "suwayomi-server";
          };
          update-branches = flake-lib.lib.mkUpdateBranches {
            inherit pkgs source;
            pinSchema = "github-asset";
          };
        };
      });
}
