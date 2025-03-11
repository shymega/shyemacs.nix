{
  inputs,
  pkgs,
}: let
  inherit (pkgs) lib;
  inherit (inputs) self;
  org = inputs.org-babel.lib;
  emacsPackage = inputs.nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.emacs-pgtk;
in
  (inputs.twist.lib.makeEnv {
    inherit emacsPackage pkgs;

    nativeCompileAheadDefault = true;
    initParser = inputs.twist.lib.parseUsePackages {
      inherit (inputs.nixpkgs) lib;
    } {};
    lockDir = ./.lock;
    initFiles = [
      (pkgs.tangleOrgBabelFile "init.el" ./README.org {
        processLines = org.excludeHeadlines (org.tag "early");
      })
    ];

    exportManifest = true;

    configurationRevision = with builtins; "${substring 0 8 self.lastModifiedDate}.${
      if self ? rev
      then substring 0 7 self.rev
      else "dirty.${substring 0 7 (hashFile "sha256" ./init.el)}"
    }";

    registries =
      inputs.twist-registries.lib.registries
      ++ [
        {
          type = "melpa";
          path = ./recipes;
        }
      ];

    inputOverrides = import ./overrides/inputOverrides.nix {inherit (inputs.nixpkgs) lib;};
  })
  .overrideScope
  (lib.composeExtensions inputs.twist-overrides.overlays.twistScope
    (_: prev: {
      elispPackages =
        prev.elispPackages.overrideScope
        (import ./overrides/packageOverrides.nix {inherit pkgs;});
    }))
