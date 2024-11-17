{
  resholve,
  bash,
  coreutils,
  which,
  git,
  jq,
  obsidian,
  bubblewrap,
  writers,
  python3Packages,
}:

let
  init-obsi-db =
    writers.writePython3Bin "init-obsi-db"
      {
        libraries = [ python3Packages.plyvel ];
      }
      ''
        import argparse
        import sys
        from pathlib import Path

        from plyvel import DB


        parser = argparse.ArgumentParser()
        parser.add_argument("path", type=Path)
        args = parser.parse_args()
        db_path = args.path

        if not db_path.parent.exists():
            print(f"ERROR: Directory '{db_path.parent}' does not exist")
            sys.exit(1)

        if not db_path.exists():
            with DB(db_path.as_posix(), create_if_missing=True) as db:
                db.put(b'_app://obsidian.md\x00\x01enable-plugin-1', b'\x01true')
      '';
in

resholve.mkDerivation {
  pname = "dev-obsidian-env";
  version = "0.1.0";
  src = builtins.path { path = ./run-obsidian.sh; };
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
        init-obsi-db
      ];
      fix = {
        "$obsidian" = [ "${obsidian}/bin/obsidian" ];
      };
      execer = [
        "cannot:${git}/bin/git"
        "cannot:${bubblewrap}/bin/bwrap"
        "cannot:${init-obsi-db}/bin/init-obsi-db"
      ];
    };
  };
}
