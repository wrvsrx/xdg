{
  leanPackages,
}:
leanPackages.buildLakePackage {
  pname = "xdg";
  version = "0.3.0-dev";
  src = builtins.path { path = ./.; };
}
