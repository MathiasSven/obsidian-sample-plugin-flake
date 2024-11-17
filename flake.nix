{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "obsidian" ];
      };

      nodejs = pkgs.nodejs_24;

      inherit (pkgs)
        buildNpmPackage
        importNpmLock
        ;

      run-obsidian = pkgs.callPackage ./nix/run-obsidian.nix { };

      release = buildNpmPackage {
        pname = "obsidian-execute-code";
        version = "2.0.0";
        src = ./.;

        inherit nodejs;

        npmDeps = importNpmLock {
          npmRoot = ./.;
        };

        npmConfigHook = importNpmLock.npmConfigHook;

        installPhase = ''
          install -m +r \
            main.js \
            manifest.json \
            styles.css \
            -D -t $out
        '';
      };
    in
    {
      packages.${system}.default = release;
      devShells.${system}.default = pkgs.mkShell {
        name = "obsidian-plugin-shell";

        packages = [
          importNpmLock.hooks.linkNodeModulesHook
          nodejs

          run-obsidian
          (pkgs.writeShellScriptBin "add-dep" ''
              npx add-dependencies "$@"
              npm i --package-lock-only
              direnv reload
          '')
        ];

        npmDeps = importNpmLock.buildNodeModules {
          npmRoot = ./.;
          inherit nodejs;
        };
      };
    };
}
