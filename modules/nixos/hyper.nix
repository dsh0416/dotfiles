{ lib, ... }:

{
  # Keep consumer overlays ahead of this compatibility repair.
  nixpkgs.overlays = lib.mkAfter [
    (final: prev: {
      hyper = prev.hyper.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.makeWrapper ];

        installPhase = old.installPhase + ''
          hyperRuntimePath=${
            final.lib.makeLibraryPath [
              final.libglvnd
              final.stdenv.cc.cc
            ]
          }

          patchelf --add-rpath "$hyperRuntimePath" "$out/opt/Hyper/hyper"

          for nativeModule in \
            "$out/opt/Hyper/resources/app.asar.unpacked/node_modules/node-pty/build/Release/pty.node" \
            "$out/opt/Hyper/resources/app.asar.unpacked/node_modules/node-pty/bin/linux-x64-107/node-pty.node"
          do
            patchelf --add-rpath "$hyperRuntimePath" "$nativeModule"
          done

          rm "$out/bin/hyper"
          makeWrapper "$out/opt/Hyper/hyper" "$out/bin/hyper" \
            --prefix LD_LIBRARY_PATH : "$hyperRuntimePath"
        '';

        meta = old.meta // {
          broken = false;
        };
      });
    })
  ];
}
