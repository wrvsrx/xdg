{
  leanPackages,
  fetchFromGitHub,
  writeText,
}:
let
  get-environment = leanPackages.buildLakePackage {
    pname = "get-environment";
    version = "0.2.0";
    src = fetchFromGitHub {
      owner = "wrvsrx";
      repo = "get-environment";
      rev = "0.2.0";
      sha256 = "sha256-qR1cgwVMtC0kEMJWs5Qj9MYD4fPni3Y78cgolVg8mhc=";
    };
    leanPackageName = "GetEnvironment";
  };
  self = leanPackages.buildLakePackage {
    pname = "xdg";
    version = "0.7.0-dev";
    src = builtins.path { path = ./.; };
    leanDeps = [ get-environment ];

    doCheck = true;
    checkPhase = ''
      lake test --no-ansi --packages=${overridesFile}
    '';
  };
  overridesFile = writeText "lake-overrides.json" (
    builtins.toJSON {
      schemaVersion = "1.2.0";
      packages = map (dep: {
        type = "path";
        name = dep.passthru.lakePackageName or dep.pname;
        inherited = false;
        dir = "${dep}";
      }) self.allLeanDeps;
    }
  );
in
self
