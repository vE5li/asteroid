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

              # Patch asteroid-app.inc directly (can't use .bbappend for .inc files)
              patch --forward -p1 -d /asteroid/src/meta-asteroid < /asteroid/patches/asteroid-app-add-qtbase.patch || true

              # Copy custom layer with fixes
              cp -r /asteroid/meta-asteroid-fixes /asteroid/src/

              # Add layer to build configuration (only if not already present)
              if ! grep -q 'meta-asteroid-fixes' /asteroid/build/conf/bblayers.conf; then
                echo 'BBLAYERS += \"/asteroid/src/meta-asteroid-fixes\"' >> /asteroid/build/conf/bblayers.conf
              fi

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
