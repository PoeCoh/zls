{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

    zig-overlay.url = "github:mitchellh/zig-overlay";
    zig-overlay.inputs.nixpkgs.follows = "nixpkgs";

    gitignore.url = "github:hercules-ci/gitignore.nix";
    gitignore.inputs.nixpkgs.follows = "nixpkgs";

    zls-src = {
      url = "github:PoeCoh/zls?shallow=0";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    zig-overlay,
    gitignore,
    zls-src,
  }:
    builtins.foldl' nixpkgs.lib.recursiveUpdate {} (
      builtins.map
      (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};
          zig = zig-overlay.packages.${system}.master;
          gitignoreSource = gitignore.lib.gitignoreSource;
          target = builtins.replaceStrings ["darwin"] ["macos"] system;
          revision = self;
        in {
          formatter.${system} = pkgs.alejandra;
          packages.${system} = rec {
            default = zls;
            zls = pkgs.stdenvNoCC.mkDerivation {
              name = "zls";
              version = "master";
              meta.mainProgram = "zls";
              #src = gitignoreSource ./.;
              src = zls-src;
              nativeBuildInputs = [ zig pkgs.git ];
              dontConfigure = true;
              dontInstall = true;
              doCheck = true;
              buildPhase = ''
                PACKAGE_DIR=${pkgs.callPackage ./deps.nix {}}
                #if [ ! -d ".git" ]; then
                #  git init --initial-branch=master
                #  git remote add origin https://github.com/PoeCoh/zls
                #  git fetch --filter=blob:none origin
                #  git reset --hard origin/master
                #fi
                zig build install --global-cache-dir $(pwd)/.cache --system $PACKAGE_DIR -Dtarget=${target} -Doptimize=ReleaseSafe --color off --prefix $out
              '';
              checkPhase = ''
                zig build test --global-cache-dir $(pwd)/.cache --system $PACKAGE_DIR -Dtarget=${target} --color off
              '';
            };
          };
        }
      )
      ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"]
    );
}
