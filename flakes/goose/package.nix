{ stdenv
, lib
, fetchurl
, autoPatchelfHook
, makeWrapper
, gcc
, glibc
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
    glibc
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

  # runmain.o is not a normal ELF; don't strip/patchelf the whole tree hard
  dontStrip = true;

  sourceRoot = "goose-v2026.3-linux-x64";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -a . $out/

    test -x $out/goose
    test -f $out/tcclib/include/tccdefs.h
    test -f $out/tcclib/libtcc1.a
    test -d $out/stdlib

    # Headers for #include <stdint.h> etc. (don't overwrite tcc's)
    cp -an ${glibc.dev}/include/. $out/tcclib/include/
    test -f $out/tcclib/include/stdint.h

    # Libraries for -lc / -lm (JIT has no /usr/lib)
    mkdir -p $out/tcclib/lib
    for so in libc.so.6 libm.so.6 libpthread.so.0 libdl.so.2 librt.so.1 \
              libresolv.so.2 libutil.so.1; do
      if [ -e "${glibc}/lib/$so" ]; then
        ln -s "${glibc}/lib/$so" "$out/tcclib/lib/$so"
      fi
    done
    # tcc resolves -lc as lib/libc.so
    ln -sf libc.so.6  $out/tcclib/lib/libc.so
    ln -sf libm.so.6  $out/tcclib/lib/libm.so
    ln -sf libpthread.so.0 $out/tcclib/lib/libpthread.so
    ln -sf libdl.so.2 $out/tcclib/lib/libdl.so

    test -e $out/tcclib/lib/libc.so

    mkdir -p $out/bin
    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/goose $out/bin/goose \
      --set-default GOOSE_STDLIB "$out/stdlib" \
      --set-default GOOSE_TCCLIB "$out/tcclib" \
      --prefix LIBRARY_PATH : "$out/tcclib/lib:${glibc}/lib" \
      --prefix LD_LIBRARY_PATH : "${glibc}/lib" \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}
  '';

  meta = with lib; {
    description = "Goose programming language (prebuilt v2026.3, TinyCC-ready on NixOS)";
    homepage = "https://github.com/aardappel/goose";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "goose";
  };
}
