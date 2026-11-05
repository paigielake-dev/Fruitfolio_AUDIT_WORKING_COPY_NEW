#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
command -v xcodebuild >/dev/null || { echo 'Xcode on macOS is required to build iOS device/simulator slices.' >&2; exit 2; }
command -v cmake >/dev/null || { echo 'CMake is required.' >&2; exit 2; }
project_dir=$(pwd)
build_dir=${FRUITFOLIO_APPLE_BUILD_DIR:-${TMPDIR:-/tmp}/fruitfolio-llama-apple-build}
output="$project_dir/Fruitfolio/Frameworks/llama.xcframework"
[[ ! -e "$output" ]] || { echo 'Preserving existing llama.xcframework; validate it before choosing a fresh rebuild location.' >&2; exit 2; }
mkdir -p "$build_dir"
for sdk in iphoneos iphonesimulator; do
  if [[ "$sdk" == iphoneos ]]; then architectures=arm64; supported_platform=iPhoneOS
  else architectures='arm64;x86_64'; supported_platform=iPhoneSimulator
  fi
  cmake -S "$project_dir/llama.cpp" -B "$build_dir/$sdk/cmake" \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" \
    -DCMAKE_OSX_ARCHITECTURES="$architectures" -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
    -DBUILD_SHARED_LIBS=OFF -DLLAMA_BUILD_COMMON=OFF -DLLAMA_BUILD_TESTS=OFF \
    -DLLAMA_BUILD_TOOLS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF \
    -DLLAMA_BUILD_APP=OFF -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON -DGGML_NATIVE=OFF
  cmake --build "$build_dir/$sdk/cmake" --target llama --parallel "${FRUITFOLIO_BUILD_JOBS:-2}"
  framework="$build_dir/$sdk/llama.framework"
  mkdir -p "$framework/Headers" "$framework/Modules"
  libraries=()
  while IFS= read -r library; do libraries+=("$library"); done < <(find "$build_dir/$sdk/cmake" -type f \( -name 'libllama.a' -o -name 'libggml*.a' \))
  [[ ${#libraries[@]} -ge 3 ]] || { echo 'Expected llama and ggml static archives were not produced.' >&2; exit 2; }
  xcrun libtool -static -o "$framework/llama" "${libraries[@]}"
  cp "$project_dir/llama.cpp/include/llama.h" "$framework/Headers/"
  cp "$project_dir/llama.cpp/ggml/include/"*.h "$framework/Headers/"
  cat > "$framework/Modules/module.modulemap" <<'MAP'
framework module llama {
  umbrella header "llama.h"
  export *
  module * { export * }
  link "c++"
  link framework "Accelerate"
  link framework "Metal"
  link framework "Foundation"
}
MAP
  python3 - "$framework/Info.plist" "$supported_platform" <<'PLIST'
from pathlib import Path
import plistlib
import sys
metadata = dict(CFBundleIdentifier='org.ggml.llama', CFBundleExecutable='llama',
                CFBundlePackageType='FMWK', CFBundleVersion='1', CFBundleShortVersionString='1.0',
                MinimumOSVersion='17.0', CFBundleSupportedPlatforms=[sys.argv[2]])
Path(sys.argv[1]).write_bytes(plistlib.dumps(metadata))
PLIST

done
xcodebuild -create-xcframework -framework "$build_dir/iphoneos/llama.framework" \
  -framework "$build_dir/iphonesimulator/llama.framework" -output "$output"
python3 Tools/verify_apple_runtime.py "$output"
