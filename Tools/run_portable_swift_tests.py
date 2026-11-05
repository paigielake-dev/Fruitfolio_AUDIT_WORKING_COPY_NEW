#!/usr/bin/env python3
"""Compile exact Foundation production files and existing tests in a temp package.

This exercises portable algorithms. It does NOT build the iOS app or substitute
for SwiftUI, UIKit, llama linking, model inference, simulator or device testing.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

SOURCES = [
    'Fruitfolio/Core/Assets/FruitfolioAssetID.swift',
    'Fruitfolio/Introduction/Prompt04LogoRevealGeometry.swift',
    'Fruitfolio/First-Launch Tour/Prompt07SpotlightGeometry.swift',
    'Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift',
    'Fruitfolio/Saved Library/Prompt10PendingSavedContent.swift',
    'Fruitfolio/Saved Library/Prompt10SavedLibraryPersistence.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioSemanticModel.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioGGUFResource.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioResearchRetrieval.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioHealthSafety.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioCanonicalVoice.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioEvidenceModels.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioEvidenceSynthesis.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioEvidenceBudget.swift',
    'Fruitfolio/LifeBridge/LifeBridgeInformation.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioLanguage.swift',
    'Fruitfolio/Ask/Prompt09ConversationPolicies.swift',
    'Fruitfolio/Ask/Prompt09AnswerSupport.swift',
    'Fruitfolio/Ask/Prompt09AskModels.swift',
    'Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift',
    'Fruitfolio/Hormone Information/HormoneMeasurement.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionModels.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionAIContext.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionEngine.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift',
    'Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift',
    'Fruitfolio/Core/Translation/FruitfolioLlamaBackend.swift',
    'Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift',
    'Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift',
    'Fruitfolio/Core/Translation/FruitfolioScientificQuantities.swift',
]
TESTS = [
    'Prompt1BBookLabelTests.swift', 'Prompt17CyclePredictionEngineTests.swift', 'Prompt1BPopupLayoutTests.swift',
    'Prompt1BDecorativeLayoutTests.swift', 'Prompt1BLifeBridgeTests.swift',
    'Prompt1BSemanticSliceTests.swift', 'Prompt1BSavedExcerptPersistenceTests.swift',
    'Prompt1BGGUFResourceTests.swift', 'Prompt1BLogoRevealTests.swift', 'Prompt1BSpotlightGeometryTests.swift',
    'Prompt1BExcerptIdentityTests.swift', 'Prompt1BAskScrollTests.swift', 'Prompt1BAskPaperLayoutTests.swift', 'Prompt1BEducationalArtworkTests.swift', 'Prompt1BCitationDestinationTests.swift', 'Prompt1BPendingSavePrivacyTests.swift', 'Prompt1BLibraryPersistenceTests.swift', 'Prompt1BResearchRetrievalTests.swift', 'Prompt1BResearchPackageTests.swift', 'Prompt1BEvidenceBoundaryTests.swift', 'Prompt1BResearchEngineIntegrationTests.swift', 'Prompt1BEvidenceBudgetTests.swift',
    'Prompt1BHormoneValidationTests.swift', 'Prompt1BFruitBasketRulesTests.swift',
    'Prompt56ResearchIntelligenceTests.swift', 'Prompt1BMADLADManifestTests.swift', 'Prompt1BScientificTranslationTests.swift',
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--swift', default='swift')
    parser.add_argument('--native-llama-build', type=Path, help='Optional existing CPU build of the checked-in llama source; no mocks or downloads')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix='fruitfolio-portable-') as temporary:
        work = Path(temporary)
        sources = work / 'Sources/Fruitfolio'
        tests = work / 'Tests/FruitfolioTests'
        sources.mkdir(parents=True)
        tests.mkdir(parents=True)
        for relative in SOURCES:
            path = root / relative
            shutil.copyfile(path, sources / path.name)
        for name in TESTS:
            shutil.copyfile(root / 'FruitfolioTests' / name, tests / name)
        extra_targets = ''
        production_target = '.target(name: "Fruitfolio")'
        language_mode = '.v6'
        if args.native_llama_build:
            build = args.native_llama_build.resolve()
            libraries = [build / 'src/libllama.a', build / 'ggml/src/libggml.a',
                         build / 'ggml/src/libggml-cpu.a', build / 'ggml/src/libggml-base.a']
            for library in libraries:
                if not library.is_file():
                    raise SystemExit(f'Missing native archive: {library}')
            module = work / 'Sources/llama'
            include = module / 'include'
            include.mkdir(parents=True)
            for directory in [root / 'llama.cpp/include', root / 'llama.cpp/ggml/include']:
                for header in directory.glob('*.h'):
                    shutil.copyfile(header, include / header.name)
            (module / 'module.modulemap').write_text('module llama [system] { header "include/llama.h" export * }\n')
            flags = [str(library) for library in libraries] + ['-lstdc++', '-lm', '-lpthread', '-ldl']
            extra_targets = '.systemLibrary(name: "llama"),'
            production_target = '.target(name: "Fruitfolio", dependencies: ["llama"], linkerSettings: [.unsafeFlags(' + json.dumps(flags) + ')])'
            # The application uses SWIFT_VERSION=5; exercise its real C branch
            # in that language mode, without relaxing regular Foundation checks.
            language_mode = '.v5'
        (work / 'Package.swift').write_text('// swift-tools-version: 6.2\nimport PackageDescription\n' +
            'let package = Package(name: "FruitfolioPortableChecks", products: [], targets: [' +
            extra_targets + production_target + ', .testTarget(name: "FruitfolioTests", dependencies: ["Fruitfolio"])], ' +
            'swiftLanguageModes: [' + language_mode + '])\n')
        environment = os.environ.copy()
        environment['FRUITFOLIO_TEST_RESEARCH_PATH'] = str(root / 'Fruitfolio/FruitfolioResearchPackage.json')
        environment['FRUITFOLIO_TEST_MODEL_PATH'] = str(root / 'FruitfolioAI.gguf')
        environment['CLANG_MODULE_CACHE_PATH'] = str(work / 'module-cache')
        environment['SWIFTPM_MODULECACHE_OVERRIDE'] = str(work / 'module-cache')
        environment['XDG_CACHE_HOME'] = str(work / 'xdg-cache')
        return subprocess.run([args.swift, 'test', '--jobs', '2',
                               '--cache-path', str(work / 'cache'),
                               '--config-path', str(work / 'configuration'),
                               '--security-path', str(work / 'security')],
                              cwd=work, env=environment).returncode

if __name__ == '__main__':
    raise SystemExit(main())
