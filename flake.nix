{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.11";
    systems.url = "github:nix-systems/default";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ez-configs = {
      url = "github:ehllie/ez-configs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    twist.url = "github:emacs-twist/twist.nix";
    org-babel.url = "github:emacs-twist/org-babel";
    emacs-lsp-booster.url = "github:slotThe/emacs-lsp-booster-flake";
    emacs-lsp-booster.inputs.nixpkgs.follows = "nixpkgs";
    emacs = {
      url = "github:emacs-mirror/emacs";
      flake = false;
    };
    twist-registries.url = "github:emacs-twist/registries";
    twist-overrides.url = "github:emacs-twist/overrides";
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = inputs: let
    inherit (inputs) self;
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        ez-configs.flakeModule
      ];
      systems = import inputs.systems ++ ["riscv64-linux" "i686-linux"];

      perSystem = {
        config,
        pkgs,
        lib,
        system,
        self,
        emacsEnv,
        emacsEarlyInit,
        ...
      }: {
        _module.args = let
          overlays = with inputs; [
            emacs-overlay.overlays.emacs
            org-babel.overlays.default
            emacs-lsp-booster.overlays.default
          ];
        in {
          pkgs = import inputs.nixpkgs {inherit system overlays;};
          emacsPackage = pkgs.emacs-pgtk;
          emacsEnv = import ./conf/emacs {inherit inputs pkgs;};
          emacsEarlyInit = let
            org = inputs.org-babel.lib;
          in (pkgs.tangleOrgBabelFile "early-init.el" ./conf/emacs/README.org {
            processLines = org.selectHeadlines (org.tag "early");
          });
          config.extraSpecialArgs = {inherit emacsEnv emacsEarlyInit;};
        };

        packages = {
          inherit emacsEnv emacsEarlyInit;
          run-emacs-on-tmpdir =
            pkgs.callPackage
            ./conf/emacs/emacs-on-tmpdir.nix
            {}
            "run-emacs-on-tmpdir"
            emacsEnv
            emacsEarlyInit;
        };

        checks = {
          # Check if the elisp packages are successfully built.
          build-env =
            emacsEnv.overrideScope (_: _: {executablePackages = [];});
        };
        apps = emacsEnv.makeApps {
          lockDirName = ".lock";
        };
      };
      ezConfigs = {
        earlyModuleArgs = {
          inherit inputs;
        };
        home = {
          modulesDirectory = ./homeModules;
        };
      };
    };
}
