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
            bash -c "source ./prepare-build.sh beluga && bitbake asteroid-image"
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
