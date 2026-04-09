{
  leanPackages,
}:
leanPackages.buildLakePackage {
  pname = "xdg";
  version = "0.3.0";
  src = builtins.path { path = ./.; };
}
