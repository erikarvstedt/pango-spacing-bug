{
  description = "Reproduce Pango bug";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.nixpkgs_21_11.url = "github:NixOS/nixpkgs/nixos-21.11";
  inputs.nixpkgs_22_05.url = "github:NixOS/nixpkgs/nixos-22.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  # Parent of bad1
  # This leads to the same output as 1.49.2
  inputs.pango_good = { url = "github:GNOME/pango/6b260a686b2c46237cb2673f23de163b252192bc"; flake = false; };

  # Part of 1.49.3
  # Author: Matthias Clasen <mclasen@redhat.com>
  # Date:   Tue Oct 19 15:12:56 2021 -0400
  # Use harfbuzz metrics for cairo fonts
  inputs.pango_bad1 = { url = "github:GNOME/pango/047bfaf6012207df2803f51617a165beced7612f"; flake = false; };

  # Part of 1.49.3
  # Author: Matthias Clasen <mclasen@redhat.com>
  # Date:   Fri Nov 5 06:57:44 2021 -0400
  # Fix advance widths with transforms
  inputs.pango_bad2 = { url = "github:GNOME/pango/ccb651dd2a876a4f4a4cb9351f05332173e709ba"; flake = false; };

  # Part of 1.49.4
  # Author: Matthias Clasen <mclasen@redhat.com>
  # Date:   Mon Nov 8 20:06:47 2021 -0500
  # Call hb_font_set_ptem when creating fonts
  inputs.pango_bad3 = { url = "github:GNOME/pango/4e9463108773bb9d45187efd61c6c395e0122187"; flake = false; };

  # (Skipped because of build failure)
  # Part of 1.49.4
  # Author: Sebastian Keller <skeller@gnome.org>
  # Date:   Mon Nov 22 01:54:15 2021 +0100
  # Calculate hinted font height based on the hinted extents
  # inputs.pango_bad4 = { url = "github:GNOME/pango/303f79e14047d60c3ca41c24931c8cb6115433ae"; flake = false; };

  # Part of 1.50.3
  # This leads to the same output as 1.50.9
  # Author: Matthias Clasen <mclasen@redhat.com>
  # Date:   Fri Dec 17 14:24:17 2021 -0500
  # Revert "Fix advance widths with transforms"
  # This reverts commit ccb651dd2a876a4f4a4cb9351f05332173e709ba (bad2)
  inputs.pango_bad5 = { url = "github:GNOME/pango/22f8df579d82f342909b629c0e94b8ff7c5452fd"; flake = false; };

  inputs.pango_1_49_2 = { url = "github:GNOME/pango/c3eacb14d8ce62491ff68ed6445fc1c3d021321d"; flake = false; };
  inputs.pango_1_50_9 = { url = "github:GNOME/pango/0fcfed29cccbdd3a703f39b0eb36a2afd0aff04e"; flake = false; };

  outputs = { self, flake-utils, nixpkgs_21_11, nixpkgs_22_05, nixpkgs, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        inherit (pkgs) lib;

        mkPangoFromRev = { rev, sha256 }: pkgs.pango.overrideAttrs (_: {
          version = builtins.substring 0 7 rev;
          src = pkgs.fetchFromGitHub {
            owner = "GNOME";
            repo = "pango";
            inherit rev sha256;
          };
        });

        mkPangoFromInput = name: input: pkgs.pango.overrideAttrs (_: {
          version = lib.removePrefix "pango_" name;
          src = input;
        });

        pangoInputs = lib.filterAttrs (name: _: lib.hasPrefix "pango" name) inputs;

        pangoVersions = {
          pango_nixos_21_11 = nixpkgs_21_11.legacyPackages.${system}.pango;
          pango_nixos_22_05 = nixpkgs_22_05.legacyPackages.${system}.pango;
        } // (
          lib.mapAttrs mkPangoFromInput pangoInputs
        );

        envVars = pangoVersions // {
          pangoVersions = builtins.concatStringsSep " " (builtins.attrNames pangoVersions);
        };

        path = lib.makeBinPath (with pkgs; [
          bubblewrap
          fontconfig
        ]);

        setEnv = ''
          PATH=${path}:$PATH
          ${
            builtins.concatStringsSep "\n" (
              lib.mapAttrsToList (name: value: ''export ${name}="${value}"'') envVars
            )
          }
        '';
      in
        rec {
          packages = pangoVersions // rec {

            default = textRenderings;

            textRenderings = pkgs.runCommand "text-renderings" {
              ETC_FONT_DIR = ./etc-fonts;
            } ''
              ${setEnv}
              mkdir $out
              cd $out
              . ${./main.sh}
            '';

            repro-env = pkgs.writeScriptBin "repro-env" ''
              ${setEnv}
              if [[ $# -gt 0 ]]; then
                exec "$@"
              else
                exec $SHELL
              fi
            '';

            manual-build-env = pkgs.pango.overrideDerivation (old: {
              nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.bubblewrap ];
            });
          };

          apps.default = { type = "app"; program = "${self.packages.${system}.repro-env}/bin/repro-env"; };
        }
    );
}
