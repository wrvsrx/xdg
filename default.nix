{
  stdenv,
  lean4,
  lakeSetupHook,
  writeText,
}:
stdenv.mkDerivation {
  pname = "xdg";
  version = "0.2.0";
  src = builtins.path { path = ./.; };
  env.NIX_LAKE_MANIFEST_OVERRIDE = writeText "lake-manifest-override.json" (builtins.toJSON [ ]);
  nativeBuildInputs = [
    lean4
    lakeSetupHook
  ];
}
