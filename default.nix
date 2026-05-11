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
  lakeHash = "sha256-cyZz+1PsuCaI2Pr5jgsv4Dv003oNXgy/DUa0lnUkBGY=";

  doCheck = true;
  checkPhase = ''
    lake test
  '';
}
