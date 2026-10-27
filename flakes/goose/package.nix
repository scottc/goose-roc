{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, makeWrapper
, gcc
, libx11
, libxext
, libxcursor
, libxi
, libxrandr
, libxfixes
, libxscrnsaver
, libxtst
, libxxf86vm
, libxkbcommon
, vulkan-loader
, alsa-lib
, dbus
, udev
, liburing
, libpulseaudio
, pipewire
, fribidi
, libthai
}:

let
  version = "2026.3";
in
stdenv.mkDerivation {
  pname = "goose";
  inherit version;

  src = fetchurl {
    url = "https://github.com/aardappel/goose/releases/download/v${version}/goose-v${version}-linux-x64.tar.gz";
    sha256 = "06ac30284338269d3996d457412bf4f2b47c1f9a5601de65b6317187fe78d5c9";
  };

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  buildInputs = [
    gcc.cc.lib
    libx11
    libxext
    libxcursor
    libxi
    libxrandr
    libxfixes
    libxscrnsaver
    libxtst
    libxxf86vm
    libxkbcommon
    vulkan-loader
    dbus
    udev
    liburing
    alsa-lib
    libpulseaudio
    pipewire
    fribidi
    libthai
  ];

  autoPatchelfIgnoreMissingDeps = [
    "libsteam_api.so"
    "libjack.so.0"
    "libsndio.so.7"
  ];

  sourceRoot = "goose-v2026.3-linux-x64";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin

    install -Dm755 goose $out/bin/goose

    for d in pkg stdlib runtime lib share; do
      if [ -d "$d" ]; then
        cp -a "$d" $out/
      fi
    done

    find . -maxdepth 1 -type f ! -name goose -exec cp -a {} $out/bin/ \; 2>/dev/null || true

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/goose \
      --set-default GOOSE_HOME "$out" \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}
  '';

  meta = with lib; {
    description = "Goose programming language (prebuilt v2026.3)";
    homepage = "https://github.com/aardappel/goose";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "goose";
  };
}
