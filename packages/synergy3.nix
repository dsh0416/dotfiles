{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libappindicator-gtk3,
  libei,
  libnotify,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxinerama,
  libxkbcommon,
  libxkbfile,
  libxrandr,
  libxtst,
  mesa,
  nspr,
  nss,
  openssl,
  pango,
  qt6,
  systemd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "synergy3";
  version = "3.6.3";

  src = requireFile {
    name = "synergy-3.6.3-linux-noble-x86_64.deb";
    sha256 = "sha256-Ge4Et9kVDap5CzlpHqT4IiuGvf7XxzD/0o2xM1FEnEA=";
    url = "https://symless.com/synergy/download";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libappindicator-gtk3
    libei
    libnotify
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxi
    libxinerama
    libxkbcommon
    libxkbfile
    libxrandr
    libxtst
    mesa
    nspr
    nss
    openssl
    pango
    qt6.qtbase
    stdenv.cc.cc.lib
    systemd
  ];

  # synergy-tray loads AppIndicator with dlopen, so autoPatchelf cannot infer
  # this runtime search path from DT_NEEDED. The service inherits the wrapper
  # environment and passes it to the tray child process.
  qtWrapperArgs = [
    "--prefix"
    "LD_LIBRARY_PATH"
    ":"
    (lib.makeLibraryPath [ libappindicator-gtk3 ])
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/opt" "$out/bin" "$out/share"
    cp -a opt/Synergy "$out/opt/Synergy"
    cp -a usr/share/applications "$out/share/"
    cp -a usr/share/icons "$out/share/"

    # The setuid helper from a Debian package cannot retain its ownership or
    # mode in the Nix store. Electron can use the kernel namespace sandbox, so
    # explicitly disable only the legacy setuid implementation.
    rm "$out/opt/Synergy/chrome-sandbox"
    makeWrapper "$out/opt/Synergy/synergy" "$out/bin/synergy" \
      --add-flags "--disable-setuid-sandbox"

    for executable in \
      synergy-core \
      synergy-diagnostics \
      synergy-legacy \
      synergy-security \
      synergy-service \
      synergy-tray
    do
      ln -s "$out/opt/Synergy/$executable" "$out/bin/$executable"
    done

    substituteInPlace "$out/share/applications/synergy.desktop" \
      --replace-fail 'Exec=/opt/Synergy/synergy %U' 'Exec=synergy %U'

    runHook postInstall
  '';

  meta = {
    description = "Keyboard and mouse sharing application";
    homepage = "https://symless.com/synergy";
    license = lib.licenses.unfree;
    mainProgram = "synergy";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})
