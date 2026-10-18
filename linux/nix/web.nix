{
  lib,
  flutter,
  self,
}:
flutter.buildFlutterApplication {
  pname = "sly-web";
  version = lib.head (
    builtins.match ".*\nversion: ([^+\n]+).*" (builtins.readFile "${self}/pubspec.yaml")
  );

  src = self;
  autoPubspecLock = "${self}/pubspec.lock";

  targetFlutterPlatform = "web";
  flutterBuildFlags = [ "--wasm" ];
}
