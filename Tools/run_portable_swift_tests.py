#!/usr/bin/env python3
"""Compile exact Foundation production files and existing tests in a temp package.

This exercises portable algorithms. It does NOT build the iOS app or substitute
for SwiftUI, UIKit, llama linking, model inference, simulator or device testing.
"""
import argparse
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
    'Fruitfolio/Core/DesignSystems/FruitfolioSemanticModel.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioGGUFResource.swift',
    'Fruitfolio/LifeBridge/LifeBridgeInformation.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioLanguage.swift',
    'Fruitfolio/Ask/Prompt09ConversationPolicies.swift',
    'Fruitfolio/Ask/Prompt09AnswerSupport.swift',
    'Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift',
    'Fruitfolio/Hormone Information/HormoneMeasurement.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionModels.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionAIContext.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionEngine.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift',
    'Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift',
    'Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift',
    'Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift',
]
TESTS = [
    'Prompt17CyclePredictionEngineTests.swift', 'Prompt1BPopupLayoutTests.swift',
    'Prompt1BDecorativeLayoutTests.swift', 'Prompt1BLifeBridgeTests.swift',
    'Prompt1BSemanticSliceTests.swift', 'Prompt1BSavedExcerptPersistenceTests.swift',
    'Prompt1BGGUFResourceTests.swift', 'Prompt1BLogoRevealTests.swift', 'Prompt1BSpotlightGeometryTests.swift',
    'Prompt1BExcerptIdentityTests.swift', 'Prompt1BAskScrollTests.swift', 'Prompt1BAskPaperLayoutTests.swift', 'Prompt1BEducationalArtworkTests.swift',
    'Prompt1BHormoneValidationTests.swift', 'Prompt1BFruitBasketRulesTests.swift',
    'Prompt1BMADLADManifestTests.swift', 'Prompt1BScientificTranslationTests.swift',
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--swift', default='swift')
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
        (work / 'Package.swift').write_text('''// swift-tools-version: 6.2
import PackageDescription
let package = Package(name: "FruitfolioPortableChecks", products: [], targets: [
    .target(name: "Fruitfolio"),
    .testTarget(name: "FruitfolioTests", dependencies: ["Fruitfolio"])
])
''')
        environment = os.environ.copy()
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
