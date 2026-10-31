{
  description = "cairn: companion code for the series 用 Cairn 从零学 Shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      devShellsBySystem = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        pkgs.mkShell {
          packages = with pkgs; [
            bashInteractive
            coreutils
            findutils
            diffutils
            gnugrep
            gnused
            gawk
            rsync
            util-linux
            procps
            shellcheck
            shfmt
            (bats.withLibraries (l: [
              l.bats-support
              l.bats-assert
              l.bats-file
            ]))
            parallel
            strace
            hyperfine
            dash
            yash
            mksh
            checkbashisms
            kcov
            gnumake
            jq
            git
            file
          ];
          shellHook = ''
            export CAIRN_BUSYBOX="${pkgs.busybox}/bin/busybox"
            export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
            echo "cairn dev shell: $(bash --version | head -n 1), shellcheck $(shellcheck --version | sed -n 's/^version: //p'), shfmt $(shfmt --version), $(bats --version)"
          '';
        }
      );
    in
    {
      devShells = nixpkgs.lib.mapAttrs (_: devShell: { default = devShell; }) devShellsBySystem;
      checks = nixpkgs.lib.mapAttrs (_: devShell: { dev-shell = devShell; }) devShellsBySystem;
    };
}
