{
  leanPackages,
}:
let
  lakefile = builtins.fromTOML (builtins.readFile ./lakefile.toml);
in
leanPackages.buildLakePackage {
  pname = lakefile.name;
  inherit (lakefile) version;
  src = builtins.path { path = ./.; };

  doCheck = true;
  checkPhase = ''
    lake test
  '';
}
