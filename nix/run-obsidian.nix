{
  resholve,
  bash,
  coreutils,
  which,
  git,
  jq,
  obsidian,
  bubblewrap,
}:

resholve.mkDerivation {
  pname = "dev-obsidian-env";
  version = "0.1.0";
  src = ./run-obsidian.sh;
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    install -D $src $out/bin/run-obsidian
  '';
  solutions = {
    default = {
      scripts = [ "bin/run-obsidian" ];
      interpreter = "${bash}/bin/bash";
      inputs = [
        git
        jq
        obsidian
        bubblewrap
        coreutils
        which
      ];
      fix = {
        "$obsidian" = [ "${obsidian}/bin/obsidian" ];
      };
      execer = [
        "cannot:${git}/bin/git"
        "cannot:${bubblewrap}/bin/bwrap"
      ];
    };
  };
}
