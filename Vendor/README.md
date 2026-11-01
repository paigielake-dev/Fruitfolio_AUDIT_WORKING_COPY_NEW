Fruitfolio links one static llama.xcframework at Vendor/llama.xcframework.
The original desktop-only absolute path has been replaced with this portable
project-relative path. The legacy Fruitfolio/Frameworks/llama.framework is
preserved but excluded from app target membership; it is a macOS binary.

The downloadable checkpoint includes the actual XCFramework produced from the
vendored source by hosted macOS CI run 41265395203 (artifact 13066884149).
Device arm64 and Simulator arm64 slices were compiled successfully with
Xcode 26.6 (17F113), Swift 6.3.3, on macOS 26.6.2. The artifact SHA-256 is
74ecf4025155b426269dfffb3939932491fac9ada6a9d1e20820edeb7b6ed601.
The raw build log and tool versions are in Fruitfolio_Verification_Evidence.
This dependency build does not establish app linking or inference acceptance.

The Git repository retains the source recipe and CI artifacts instead of
tracking generated runtime binaries. Run Tools/build_ios_llama.sh on a Mac
with Xcode and CMake to recreate the framework. It refuses to replace an
existing framework implicitly. It embeds the Metal library and combines
static llama/ggml archives. The app links it without dynamic embedding.
Intel Mac simulator support is not included in this recipe or framework.
See llama.cpp/LICENSE and its source licenses for the vendored dependencies.
