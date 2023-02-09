{ pkgs ? import <nixpkgs> {config.allowBroken = true;} }:

# pkgs.haskellPackages.shellFor {
#   packages = p: [ (pkgs.haskellPackages.callPackage ../taffybar.nix { }) ];
#   nativeBuildInputs = with pkgs.haskellPackages; [
#     cabal-install hlint ghcid ormolu implicit-hie haskell-language-server (callPackage ../taffy.nix { })
#   ];
# }
pkgs.mkShell {
  allowBroken = true;
  buildInputs = [
    pkgs.hello
    pkgs.haskell-language-server
    (pkgs.haskellPackages.ghcWithPackages (self: [
      # self.xmonad
      # self.dbus
      # self.cabal-install
      # self.hlint
      # self.ghcid
      # self.ormolu
      # self.implicit-hie
      self.simple-cmd
      (pkgs.haskellPackages.callPackage ../taffy.nix { })
      # (pkgs.haskellPackages.callPackage ../taffybar.nix { })
      # self.network
      # self.xmonad-contrib
      # self.xmonad-extras
    ]))
    # keep this line if you use bash
    pkgs.bashInteractive
  ];
}
