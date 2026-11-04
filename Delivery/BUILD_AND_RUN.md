# Open and verify this checkpoint

1. On a Mac, install/select Xcode and its iOS Simulator runtime. Open
   Fruitfolio.xcodeproj and use the shared Fruitfolio scheme. The source uses
   modern Swift syntax; the actual CI Xcode/Swift versions are recorded in
   Fruitfolio_Verification_Evidence/Build when available.
2. If Vendor/llama.xcframework is not present, run:

       bash Tools/build_ios_llama.sh

   The recipe builds the vendored runtime for arm64 iOS and arm64 Simulator.
   It does not replace an existing verified framework. Intel Mac simulator
   support is not included. CMake and the Xcode iOS SDK are required.
3. FruitfolioAI.gguf must remain at the project root and in Copy Bundle
   Resources exactly once. Fruitfolio/FruitfolioResearchPackage.json is
   included through the synchronized app source group.
4. Choose an installed iPhone simulator and build/run. Select your own signing
   team for a physical device. No paid developer credentials are supplied.
5. Run Product -> Test, including unit and UI test targets. The manual GitHub
   workflow performs equivalent build/test work and preserves its xcresult.
6. Export real screenshots from xcresult, compare all Prompt 1B states, and
   perform VoiceOver, Dynamic Type, Reduced Motion, audio and actual-device
   model/memory testing. A successful build alone is not release acceptance.

Research import can be reproduced with Python, python-docx and Poppler:

    python Tools/build_research_package.py \
      --corpus PATH/TO/FruitsofLife_xo_Research_Corpus_APA7.docx \
      --guide PATH/TO/FruitsofLife.xo_Pregnancy_Postpartum_Wellness_Guide.pdf \
      --output Fruitfolio/FruitfolioResearchPackage.json \
      --provenance Delivery/ResearchImportProvenance.json

The original DOCX and PDF are preserved in the ResearchLibrary asset catalog.
The importer is deterministic; review its unresolved references before treating
imported citation strings as normalized APA7 or externally verified evidence.

MADLAD resources are preserved outside the app target while its compatibility
and medical translation gates remain unresolved. Do not simply add the original
Candle-format GGUF to the app bundle and call the translation system complete.
