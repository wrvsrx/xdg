{ stdenvNoCC, lean4 }:
stdenvNoCC.mkDerivation {
  name = "xdg";
  src = ./.;
  nativeBuildInputs = [ lean4 ];
  installPhase = ''
    mkdir -p $out
  '';
}
