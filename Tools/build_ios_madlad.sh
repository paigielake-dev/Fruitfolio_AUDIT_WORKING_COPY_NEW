#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source_root=TranslationInvestigation/candle-runtime-investigation
if [ ! -f "$source_root/candle-core/Cargo.toml" ]; then
  git clone https://github.com/huggingface/candle.git "$source_root"
  git -C "$source_root" checkout 2cf0e66dcb2953e2aa7f4000cdd697239e9c16c5
fi
python3 Tools/prepare_candle_madlad.py
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
for target in aarch64-apple-ios aarch64-apple-ios-sim; do
  if [ "$target" = aarch64-apple-ios ]; then sdk=iphoneos; else sdk=iphonesimulator; fi
  SDKROOT="$(xcrun --sdk "$sdk" --show-sdk-path)" IPHONEOS_DEPLOYMENT_TARGET=17.0 \
    cargo build --release --lib -j 2 --target "$target" \
    --manifest-path TranslationInvestigation/madlad-candle-probe/Cargo.toml
 done
mkdir -p Vendor
# Static XCFrameworks share Xcode's product include directory. Namespace
# MADLAD's headers so its module map cannot overwrite llama's module map.
staging_root="$(mktemp -d)"
headers_root="$staging_root/Headers"
trap 'rm -rf "$staging_root"' EXIT
mkdir -p "$headers_root/FruitfolioMADLADRuntime"
cp TranslationInvestigation/madlad-candle-probe/include/FruitfolioMADLAD.h "$headers_root/FruitfolioMADLADRuntime/"
cp TranslationInvestigation/madlad-candle-probe/include/module.modulemap "$headers_root/FruitfolioMADLADRuntime/"
xcodebuild -create-xcframework \
 -library TranslationInvestigation/madlad-candle-probe/target/aarch64-apple-ios/release/libfruitfolio_madlad.a \
 -headers "$headers_root" \
 -library TranslationInvestigation/madlad-candle-probe/target/aarch64-apple-ios-sim/release/libfruitfolio_madlad.a \
 -headers "$headers_root" \
 -output "$staging_root/FruitfolioMADLAD.xcframework"
# Replace the reproducible artifact only after both slices package successfully.
rm -rf Vendor/FruitfolioMADLAD.xcframework
mv "$staging_root/FruitfolioMADLAD.xcframework" Vendor/FruitfolioMADLAD.xcframework
