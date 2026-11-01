The app requires one llama.xcframework at Vendor/llama.xcframework.
The baseline referenced /Users/paigelake/Desktop/llama.xcframework; that
nonportable path has been replaced. The bundled Fruitfolio/Frameworks/llama.framework
is a legacy macOS binary, not a verified iOS XCFramework, and is excluded from
automatic app target membership. It is preserved in this checkpoint.

An iOS-compatible binary is still required before Xcode can build the app.
Use the matching vendored llama.cpp source and Apple's iOS SDK to produce or
verify a framework exposing module llama. Do not link both binaries.
No iOS binary is fabricated by the Linux build. The Linux shared libraries
are testing artifacts only and must never be embedded into the iOS app.

Tools/build_ios_llama.sh is the staged build recipe for arm64 iOS and arm64
Simulator. It combines static llama/ggml archives, embeds the Metal library,
and produces the expected XCFramework. This script has NOT run on macOS;
its results and Swift import/link compatibility are NOT VERIFIED. Intel
Mac simulator support is not included in this recipe. The Xcode target now
links this static dependency without embedding it as a dynamic framework.
