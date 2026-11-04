#!/bin/bash
# Build the vendored runtime for Apple SDKs. Requires macOS, Xcode and CMake.
set -euo pipefail
project_root="$(cd "$(dirname "$0")/.." && pwd)"
if [[ "$(uname -s)" != Darwin ]]; then
    echo 'This script requires macOS and the iOS SDK.' >&2
    exit 1
fi
command -v cmake >/dev/null
xcodebuild -version
runtime_build="$project_root/.build-apple-runtime"
mkdir -p "$runtime_build/headers" "$project_root/Vendor"
cp "$project_root/llama.cpp/include/llama.h" "$runtime_build/headers/"
cp "$project_root/llama.cpp/ggml/include/"*.h "$runtime_build/headers/"
cat > "$runtime_build/headers/module.modulemap" <<'MODULE'
module llama {
    header "llama.h"
    export *
}
MODULE
for sdk in iphoneos iphonesimulator; do
    slice_dir="$runtime_build/$sdk"
    cmake -S "$project_root/llama.cpp" -B "$slice_dir" -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS -DCMAKE_OSX_SYSROOT="$sdk" \
        -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
        -DBUILD_SHARED_LIBS=OFF -DGGML_NATIVE=OFF -DGGML_OPENMP=OFF \
        -DGGML_METAL=ON -DGGML_METAL_EMBED_LIBRARY=ON \
        -DLLAMA_BUILD_COMMON=OFF -DLLAMA_BUILD_TESTS=OFF \
        -DLLAMA_BUILD_TOOLS=OFF -DLLAMA_BUILD_APP=OFF \
        -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF
    cmake --build "$slice_dir" --config Release --target llama --parallel 4
    # Combine llama and its statically built ggml backends into one archive.
    archives=()
    while IFS= read -r -d '' archive; do archives+=("$archive"); done < <(
        find "$slice_dir" -path '*Release*' -name '*.a' -print0
    )
    if [[ ${#archives[@]} -eq 0 ]]; then echo 'No static runtime archives found.' >&2; exit 1; fi
    xcrun libtool -static -o "$runtime_build/libllama-$sdk.a" "${archives[@]}"
done
# Avoid replacing an existing verified framework implicitly.
if [[ -e "$project_root/Vendor/llama.xcframework" ]]; then
    echo 'Vendor/llama.xcframework already exists; preserve it or move it before rebuilding.' >&2
    exit 1
fi
xcodebuild -create-xcframework \
    -library "$runtime_build/libllama-iphoneos.a" -headers "$runtime_build/headers" \
    -library "$runtime_build/libllama-iphonesimulator.a" -headers "$runtime_build/headers" \
    -output "$project_root/Vendor/llama.xcframework"
