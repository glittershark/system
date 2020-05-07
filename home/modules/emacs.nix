{ pkgs, lib, ... }:

let
 # doom-emacs = pkgs.callPackage (builtins.fetchTarball {
 #   url = https://github.com/vlaci/nix-doom-emacs/archive/master.tar.gz;
 # }) {
 #   doomPrivateDir = ./doom.d;  # Directory containing your config.el init.el
 #                               # and packages.el files
 # };
in {
  # imports = [ ./lib/cloneRepo.nix ];

  # home.packages = [ doom-emacs ];
  # home.file.".emacs.d/init.el".text = ''
  #     (load "default.el")
  # '';
  #

  home.packages = with pkgs; [
    # haskellPackages.Agda BROKEN

    # LaTeX (for org export)
    (pkgs.texlive.combine {
      inherit (pkgs.texlive)
        scheme-basic collection-fontsrecommended ulem
        fncychap titlesec tabulary varwidth framed fancyvrb float parskip
        wrapfig upquote capt-of needspace;
    })

    ispell

    gnutls
  ];

  programs.emacs.enable = true;

  impure.clonedRepos = {
    orgClubhouse = {
      github = "glittershark/org-clubhouse";
      path = "code/org-clubhouse";
    };

    doomEmacs = {
      github = "hlissner/doom-emacs";
      path = ".emacs.d";
      after = ["emacs.d"];
      onClone = "bin/doom install";
    };

    "emacs.d" = {
      github = "glittershark/emacs.d";
      path = ".doom.d";
      after = ["orgClubhouse"];
    };
  };

  # Notes
  services.syncthing = {
    enable = true;
    tray = true;
  };
}
