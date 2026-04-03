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
          docker build --tag asteroidos-toolchain .
          docker run \
            --rm \
            -it \
            -v /etc/passwd:/etc/passwd:ro \
            -u "$(id -u):$(id -g)" \
            -v "$HOME/.config/git/config:/$HOME/.gitconfig:ro" \
            -v "$(pwd):/asteroid" \
            asteroidos-toolchain \
            bash -c "
              # Fetch all sources using prepare-build.sh
              source ./prepare-build.sh beluga

              # Copy our custom fixes layer into the source tree
              cp -r /asteroid/meta-asteroid-fixes /asteroid/src/

              # Add meta-asteroid-fixes to bblayers.conf (only if not already present)
              if ! grep -q 'meta-asteroid-fixes' /asteroid/build/conf/bblayers.conf; then
                echo 'BBLAYERS += \"/asteroid/src/meta-asteroid-fixes\"' >> /asteroid/build/conf/bblayers.conf
              fi

              # Clean state for packages we're fixing with bbappends
              # This ensures BitBake picks up the new recipe modifications
              bitbake -c cleansstate qml-asteroid mlite extra-cmake-modules asteroid-launcher

              # Build the image
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
