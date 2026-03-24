{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = (import nixpkgs) {inherit system;};

        build = pkgs.writeShellScriptBin "build" ''
          sudo docker build --tag asteroidos-toolchain .
          sudo docker run \
            --rm \
            -it \
            -v /etc/passwd:/etc/passwd:ro \
            -u "$(id -u):$(id -g)" \
            -v "$HOME/.config/git/config:/$HOME/.gitconfig:ro" \
            -v "$(pwd):/asteroid" \
            asteroidos-toolchain \
            bash -c "
              # Fetch all sources
              source ./prepare-build.sh beluga

              # Apply ECM cross-compilation patch (use absolute path since prepare-build.sh changes directory)
              ECM_RECIPE_DIR='/asteroid/src/meta-asteroid/recipes-devtools/cmake/extra-cmake-modules'
              mkdir -p \"\$ECM_RECIPE_DIR\"
              cp /asteroid/patches/ecm-crosscompile.patch \"\$ECM_RECIPE_DIR/\"

              # Add patch to recipe if not already present
              if ! grep -q 'ecm-crosscompile.patch' \"/asteroid/src/meta-asteroid/recipes-devtools/cmake/extra-cmake-modules_git.bb\"; then
                echo 'SRC_URI += \"file://ecm-crosscompile.patch\"' >> \"/asteroid/src/meta-asteroid/recipes-devtools/cmake/extra-cmake-modules_git.bb\"
              fi

              # Apply asteroid-launcher mlite dependency patch
              patch -p1 -d /asteroid/src/meta-asteroid < /asteroid/patches/asteroid-launcher-add-mlite.patch || true

              # Run the build
              bitbake asteroid-image
            "
        '';
      in {
        formatter = pkgs.alejandra;

        devShell =
          pkgs.mkShell
          {
            buildInputs = [
              build
            ];
          };
      }
    );
}
