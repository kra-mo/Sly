{ pkgs, lib }:
let
  android = pkgs.androidenv.composeAndroidPackages {
    toolsVersion = "26.1.1";
    platformToolsVersion = "36.0.1";
    buildToolsVersions = [
      "35.0.0"
      "36.0.0"
    ];
    cmakeVersions = [ "3.22.1" ];
    platformVersions = [ "36" ];
    abiVersions = [
      "armeabi-v7a"
      "arm64-v8a"
    ];
    includeNDK = true;
    ndkVersions = [ "28.2.13676358" ];
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    (flutter.override {
      extraPkgConfigPackages = [
        cairo.dev
        fribidi.dev
      ];
    })
    android.platform-tools
  ];

  env = rec {
    CPATH = lib.concatStringsSep ":" [
      "${pkgs.fribidi.dev}/include/fribidi"
      (lib.makeSearchPath "include" [
        pkgs.cairo.dev
      ])
    ];

    ANDROID_HOME = "${android.androidsdk}/libexec/android-sdk";
    ANDROID_SDK_ROOT = ANDROID_HOME;
    JAVA_HOME = pkgs.jdk17;

    TOOLS = "${ANDROID_HOME}/build-tools/${"36.0.0"}";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${TOOLS}/aapt2";
  };
}
