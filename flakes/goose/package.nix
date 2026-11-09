{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  gcc,
  libx11,
  libxext,
  libxcursor,
  libxi,
  libxrandr,
  libxfixes,
  libxscrnsaver,
  libxtst,
  libxxf86vm,
  libxkbcommon,
  vulkan-loader,
  dbus,
  udev,
  liburing,
  alsa-lib,
  libpulseaudio,
  pipewire,
  fribidi,
  libthai,
}:

stdenv.mkDerivation rec {
  pname = "goose";
  version = "2026.4";

  src = fetchurl {
    url = "https://github.com/aardappel/goose/releases/download/v${version}/goose-v${version}-linux-x64.tar.gz";
    # Replace after: nix-prefetch-url <url>
    # Or let `nix build` print got: sha256-...
    sha256 = "sha256-VZrXVy34n80Sc1EthnlSi834dsJS7B8xYI04CLJBJbM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

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

  sourceRoot = "goose-v${version}-linux-x64";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 goose $out/bin/goose

    # Runtime assets at store root (stdlib, etc.)
    for d in pkg stdlib runtime lib share tcclib; do
      if [ -d "$d" ]; then
        cp -a "$d" $out/
      fi
    done

    # libtcc looks beside the executable: $out/bin/tcclib/...
    if [ -d tcclib ]; then
      cp -a tcclib $out/bin/tcclib
    fi

    find . -maxdepth 1 -type f ! -name goose -exec cp -a {} $out/bin/ \; 2>/dev/null || true
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/goose \
      --set-default GOOSE_STORE "$out" \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}
  '';

  meta = with lib; {
    description = "Goose programming language (prebuilt v${version})";
    homepage = "https://github.com/aardappel/goose";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "goose";
  };
}
