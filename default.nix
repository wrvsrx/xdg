{
  leanPackages,
}:
leanPackages.buildLakePackage {
  pname = "xdg";
  version = "0.9.0-dev";
  src = builtins.path { path = ./.; };
  lakeHash = "sha256-cyZz+1PsuCaI2Pr5jgsv4Dv003oNXgy/DUa0lnUkBGY=";

  doCheck = true;
  checkPhase = ''
    lake test
  '';
}
