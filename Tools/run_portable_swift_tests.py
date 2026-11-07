#!/usr/bin/env python3
"""Compile exact Foundation production files and existing tests in a temp package.

This exercises portable algorithms. It does NOT build the iOS app or substitute
for SwiftUI, UIKit, llama linking, model inference, simulator or device testing.
"""
import argparse
import json
import os
import platform
from pathlib import Path
import shutil
import subprocess
import tempfile

SOURCES = [
    "Fruitfolio/Privacy Settings/Prompt12AccountPrivacyStore.swift",
    "Fruitfolio/Fruit Popup Engine/FruitPopupModels.swift",
    "Fruitfolio/Core/AppArchitecture/PopupCoordinator.swift",
    "Fruitfolio/Core/AppArchitecture/FruitfolioOwnedPopupSession.swift",
    "Fruitfolio/Hormone Information/HormoneMeasurementDeletionIntent.swift",
    "Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift",
    "Fruitfolio/Privacy Settings/FruitfolioOwnershipVerification.swift",
    "Fruitfolio/Core/Translation/FruitfolioCitationProtection.swift",
    "Fruitfolio/Core/Translation/FruitfolioModelChecksum.swift",
    "Fruitfolio/Hub/Contact/Prompt30ContactDestination.swift",
    "Fruitfolio/Fruit Basket/Prompt28RulesCopy.swift",
    "Fruitfolio/Guide Builder/Prompt11GuideBuilderModels.swift",
    "Fruitfolio/Guide Builder/Prompt11GuideFormSession.swift",
    "Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift",
    "Fruitfolio/Fruit Basket/Prompt28LevelResetSession.swift",
    "Fruitfolio/Hub/FAQ/Prompt29FAQCatalog.swift",
    'Fruitfolio/Fruit Basket/Prompt28RoundLedger.swift',
    'Fruitfolio/Fruit Basket/Prompt28SavedResearchCopy.swift',
    'Fruitfolio/Fruit Basket/Prompt28GamePersistence.swift',
    'Fruitfolio/Fruit Basket/Prompt28ProgressionPolicy.swift',
    'Fruitfolio/Fruit Basket/Prompt28ObstaclePhysics.swift',
    'Fruitfolio/Fruit Basket/Prompt28ObstacleGeometry.swift',
    'Fruitfolio/Fruit Basket/Prompt28CatchPresentation.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift',
    'Fruitfolio/Cycle Tracker/Body Biology/Prompt21BodyBiologyModels.swift',
    'Fruitfolio/Cycle Tracker/Body Biology/Prompt21BodyBiologyEngine.swift',
    'Fruitfolio/Cycle Tracker/Body Biology/Prompt21BodyBiologyLoader.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioScientificArtSizing.swift',
    'Fruitfolio/Core/Assets/FruitfolioAssetID.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioCanonicalCalendar.swift',
    'Fruitfolio/Cycle Tracker/Symptoms/Prompt23SymptomsModels.swift',
    'Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsModels.swift',
    'Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsEngine.swift',
    'Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsLoader.swift',
    'Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift',
    'Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogStore.swift',
    'Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogRules.swift',
    'Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogViewModel.swift',
    'Fruitfolio/Cycle Tracker/Daily Logging/Prompt20CalendarProjection.swift',
    'Fruitfolio/Cycle Tracker/Daily Logging/Prompt20CalendarIntegration.swift',
    'Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleModels.swift',
    'Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleLogicEngine.swift',
    'Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CyclePersistence.swift',
    'Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleStore.swift',
    'Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleSync.swift',
    'Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingModels.swift',
    'Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingPersistence.swift',
    'Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift',
    'Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingViewModel.swift',
    'Fruitfolio/Cycle Tracker/Prompt1BCycleModalRegressionHarness.swift',
    'Fruitfolio/Cycle Tracker/Today/Prompt16TodayModels.swift',
    'Fruitfolio/Cycle Tracker/Today/Prompt16PredictionPopupRequest.swift',
    'Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarLoader.swift',
    'Fruitfolio/Cycle Tracker/Cycle Wheel/Prompt18CycleWheelModels.swift',
    'Fruitfolio/Cycle Tracker/Cycle Wheel/Prompt18CycleWheelBuilder.swift',
    'Fruitfolio/Cycle Tracker/Cycle Wheel/Prompt18EstimatedIntervalAdapter.swift',
    'Fruitfolio/Cycle Tracker/Cycle Wheel/Prompt18WheelNoteLayout.swift',
    'Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarModels.swift',
    'Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarEngine.swift',
    'Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarPresentationPolicy.swift',
    'Fruitfolio/Context Personalization/Prompt27AContextModels.swift',
    'Fruitfolio/Context Personalization/FruitfolioPersonalHealthContext.swift',
    'Fruitfolio/Context Personalization/Prompt27AContextPersistence.swift',
    'Fruitfolio/Context Personalization/Prompt27ALocalContextPersistence.swift',
    'Fruitfolio/Context Personalization/Prompt27AContextStore.swift',
    'Fruitfolio/Context Personalization/Prompt27AContextPolicyEngine.swift',
    'Fruitfolio/Context Personalization/Prompt27AContextSafety.swift',
    'Fruitfolio/Context Personalization/Prompt27AContextIntegration.swift',
    'Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift',
    'Fruitfolio/Hormone Information/HormoneMeasurementStore.swift',
    'Fruitfolio/Hormone Information/HormoneLibraryProvider.swift',
    'Fruitfolio/Hormone Information/HormoneAdjustmentPolicy.swift',
    'Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmModels.swift',
    'Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmEngine.swift',
    'Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmLoader.swift',
    'Fruitfolio/Cycle Tracker/Fertilization/Prompt25FertilizationModels.swift',
    'Fruitfolio/Cycle Tracker/Fertilization/Prompt25FertilizationContent.swift',
    'Fruitfolio/Core/Intelligence/FruitfolioEducationResearch.swift',
    'Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationModels.swift',
    'Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationCatalog.swift',
    'Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyResearchBridge.swift',
    'Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationSafety.swift',
    'Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyAssetAudit.swift',
    'Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ScienceModels.swift',
    'Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ScientificAssetCatalog.swift',
    'Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ResearchBridge.swift',

    'Fruitfolio/Core/AppArchitecture/FruitfolioPseudonymPolicy.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioUsernamePersistence.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift',
    'Fruitfolio/Privacy Settings/Prompt12AccountActionRegressionHarness.swift',
    'Fruitfolio/Saved Library/Prompt10BookMotion.swift',
    'Fruitfolio/Saved Library/Prompt10UserMaterial.swift',
    'Fruitfolio/Saved Library/Prompt10SharedLibraryCatalog.swift',
    'Fruitfolio/Introduction/Prompt04LogoRevealGeometry.swift',
    'Fruitfolio/First-Launch Tour/Prompt07SpotlightGeometry.swift',
    'Fruitfolio/First-Launch Tour/Prompt07TourCopy.swift',
    'Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift',
    'Fruitfolio/Saved Library/Prompt10PendingSavedContent.swift',
    'Fruitfolio/Saved Library/Prompt10SavedLibraryPersistence.swift',
    'Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift',
    'Fruitfolio/Saved Library/Prompt10SavedLibraryAssets.swift',
    'Fruitfolio/Core/Persistence/FruitfolioJSONFieldCoverage.swift',
    'Fruitfolio/Introduction/Prompt04IntroCheckpoint.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioSemanticModel.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioReviewedSemanticContexts.swift',
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
    'Fruitfolio/Core/DataExport/FruitfolioZIPArchive.swift',
    'Fruitfolio/Core/DataExport/FruitfolioLocalDataExport.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioLanguage.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift',
    'Fruitfolio/Core/AppArchitecture/SettingsStore.swift',
    'Fruitfolio/Core/DesignSystems/FruitfolioAudioDesign.swift',
    'Fruitfolio/Ask/Prompt09ConversationPolicies.swift',
    'Fruitfolio/Ask/Prompt09AnswerSupport.swift',
    'Fruitfolio/Ask/Prompt09AskModels.swift',
    'Fruitfolio/Ask/FruitfolioAskUserContext.swift',
    'Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift',
    'Fruitfolio/Hormone Information/HormoneMeasurement.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionModels.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionAIContext.swift',
    'Fruitfolio/Cycle Tracker/Cycle Prediction Engine/Prompt17CyclePredictionEngine.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift',
    'Fruitfolio/Fruit Basket/Prompt28FruitBasketAssetUsage.swift',
    'Fruitfolio/Core/Assets/FruitfolioAsset.swift',
    'Fruitfolio/Core/Assets/AssetRegistry.swift',
    'Fruitfolio/Core/Assets/AssetUsageLedger.swift',
    'Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift',
    'Fruitfolio/Core/Translation/FruitfolioLlamaBackend.swift',
    'Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift',
    'Fruitfolio/Core/Translation/FruitfolioControlTranslationState.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioSettingsPercentage.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioUsernameExitSession.swift',
    'Fruitfolio/Core/AppArchitecture/FruitfolioAccountDraftExitRequest.swift',
    'Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift',
    'Fruitfolio/Core/Translation/FruitfolioScientificQuantities.swift',
]
TESTS = [
    'Prompt28FruitBasketTests.swift', 'Prompt1BFruitBasketQuestionOwnershipTests.swift',
    'Prompt1BCatalogTranslationTests.swift',
    'Prompt1BSavedDraftConflictTests.swift',
    'Prompt1BContextConfirmationRevisionTests.swift',
    'Prompt1BContextSnapshotProtectionTests.swift',
    'Prompt1BOwnedConfirmationTests.swift',
    'Prompt1BHormoneMeasurementTests.swift',
    'Prompt1BHormoneSnapshotProtectionTests.swift',
    'Prompt10SavedLibraryTests.swift',
    'Prompt1BLibrarySnapshotProtectionTests.swift',
    'Prompt1BLocalDataExportTests.swift',
    'Prompt1BAccountPersistenceTests.swift',
    'Prompt1BSettingsLanguageTests.swift',
    'Prompt1BExplicitLocalizationTests.swift',
    'Prompt12AccountPrivacyStoreTests.swift', 'Prompt1BAccountActionTests.swift',
    'Prompt1BOwnershipValidationTests.swift',
    'Prompt1BAccountRestorationPolicyTests.swift',
    'Prompt06FruitPopupTests.swift',
    'Prompt1BOwnershipRecordPolicyTests.swift',
    'Prompt1BCitationTranslationTests.swift',
    'Prompt1BSavedTranslationBoundaryTests.swift',
    'Prompt1BLanguagePreferencesTests.swift',
    'Prompt1BContactDestinationTests.swift',
    'Prompt1BGameRulesCatalogTests.swift',
    'Prompt1BRoundLedgerTests.swift', 'Prompt1BGameSavedSourceTests.swift',
    'Prompt1BGamePersistenceTests.swift', 'Prompt1BProgressionPolicyTests.swift',
    'Prompt1BObstaclePhysicsTests.swift',
    'Prompt1BObstacleGeometryTests.swift',
    'Prompt1BCatchPresentationTests.swift',
    'Prompt1BFruitBasketResearchTests.swift', 'Prompt1BHealthSafetyBoundaryTests.swift',
    'Prompt21BodyBiologyCoreTests.swift',
    'Prompt25FertilizationCoreTests.swift',
    'Prompt1BEducationResearchTests.swift',
    'Prompt26PregnancyEducationTests.swift',
    'Prompt1BScientificArtSizingTests.swift',
    'Prompt1BSymptomTimelineTests.swift', 'Prompt24TrendsCoreTests.swift',
    'Prompt1BDailyLogWriteTests.swift', 'Prompt20DailyLogCoreTests.swift', 'Prompt1BDailyLogViewModelTests.swift',
    'Prompt1BUsernamePersistenceTests.swift', 'Prompt1BPseudonymPolicyTests.swift', 'Prompt1BSharedLibraryCatalogTests.swift', 'Prompt11GuideBuilderTests.swift', 'Prompt1BGuideFormOwnershipTests.swift', 'Prompt1BUserMaterialTests.swift', 'Prompt1BBookMotionTests.swift', 'Prompt1BBookLabelTests.swift', 'Prompt17CyclePredictionEngineTests.swift', 'Prompt1BPopupLayoutTests.swift', 'Prompt1BPredictionPopupTests.swift',
    'Prompt1BDecorativeLayoutTests.swift', 'Prompt1BLifeBridgeTests.swift',
    'Prompt1BIntroCheckpointTests.swift', 'Prompt1BSemanticSliceTests.swift', 'Prompt1BSavedExcerptPersistenceTests.swift',
    'Prompt1BGGUFResourceTests.swift', 'Prompt1BLogoRevealTests.swift', 'Prompt1BSpotlightGeometryTests.swift',
    'Prompt1BExcerptIdentityTests.swift', 'Prompt1BAskScrollTests.swift', 'Prompt1BAskPaperLayoutTests.swift', 'Prompt1BEducationalArtworkTests.swift', 'Prompt1BCitationDestinationTests.swift', 'Prompt1BPendingSavePrivacyTests.swift', 'Prompt1BLibraryPersistenceTests.swift', 'Prompt1BResearchRetrievalTests.swift', 'Prompt1BResearchPackageTests.swift', 'Prompt1BEvidenceBoundaryTests.swift', 'Prompt1BResearchEngineIntegrationTests.swift', 'Prompt1BEvidenceBudgetTests.swift',
    'Prompt1BHormoneCivilDateTests.swift', 'Prompt1BCanonicalCalendarTests.swift', 'Prompt1BTodaySnapshotTests.swift', 'Prompt13CycleEngineTests.swift', 'Prompt14CycleOnboardingTests.swift', 'Prompt1BCycleFileProtectionTests.swift', 'Prompt1BCycleTransactionTests.swift', 'Prompt1BOnboardingTransactionTests.swift', 'Prompt1BOnboardingViewModelTests.swift', 'Prompt1BRecoveredCycleLoaderTests.swift', 'Prompt16TodayStateBuilderTests.swift', 'Prompt1BCalendarPresentationPolicyTests.swift', 'Prompt1BWheelNoteLayoutTests.swift', 'Prompt18CycleWheelTests.swift', 'Prompt19CalendarEngineTests.swift', 'Prompt1BAskUserContextTests.swift', 'Prompt1BPersonalHealthContextTests.swift', 'Prompt1BContextPersistenceTests.swift', 'Prompt27AContextPersonalizationTests.swift', 'Prompt1BHormoneAdjustmentTests.swift', 'Prompt22HormoneRhythmCoreTests.swift', 'Prompt1BHormoneLibraryTests.swift', 'Prompt1BHormonePersistenceTests.swift', 'Prompt1BHormoneValidationTests.swift', 'Prompt1BFruitBasketRulesTests.swift',
    'Prompt1BAccountDraftExitTests.swift', 'Prompt1BUsernameExitSessionTests.swift', 'Prompt1BLevelResetSessionTests.swift', 'Prompt1BControlTranslationStateTests.swift', 'Prompt1BT5ExecutionContractTests.swift', 'Prompt56ResearchIntelligenceTests.swift', 'Prompt1BMADLADManifestTests.swift', 'Prompt1BScientificTranslationTests.swift',
]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--swift', default='swift')
    parser.add_argument('--native-llama-build', type=Path, help='Optional existing CPU build of the checked-in llama source; no mocks or downloads')
    parser.add_argument('--test-filter', help='Optional Swift test name filter for focused diagnostics; omit for complete verification')
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
        crypto_dependency = []
        crypto_flags = []
        if platform.system() == 'Linux' and Path('/usr/include/openssl/evp.h').is_file():
            crypto = work / 'Sources/FruitfolioOpenSSL'
            crypto.mkdir()
            (crypto / 'shim.h').write_text('#include <openssl/evp.h>\n')
            (crypto / 'module.modulemap').write_text('module FruitfolioOpenSSL [system] { header "shim.h" link "crypto" export * }\n')
            extra_targets = '.systemLibrary(name: "FruitfolioOpenSSL"),'
            crypto_dependency = ['FruitfolioOpenSSL']
            crypto_flags = ['-lcrypto']
        production_target = '.target(name: "Fruitfolio", dependencies: ' + json.dumps(crypto_dependency) + ')'
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
            flags = [str(library) for library in libraries] + ['-lstdc++', '-lm', '-lpthread', '-ldl'] + crypto_flags
            extra_targets += '.systemLibrary(name: "llama"),'
            production_target = '.target(name: "Fruitfolio", dependencies: ' + json.dumps(crypto_dependency + ['llama']) + ', linkerSettings: [.unsafeFlags(' + json.dumps(flags) + ')])'
            # The application uses SWIFT_VERSION=5; exercise its real C branch
            # in that language mode, without relaxing regular Foundation checks.
            language_mode = '.v5'
        (work / 'Package.swift').write_text('// swift-tools-version: 6.2\nimport PackageDescription\n' +
            'let package = Package(name: "FruitfolioPortableChecks", products: [], targets: [' +
            extra_targets + production_target + ', .testTarget(name: "FruitfolioTests", dependencies: ["Fruitfolio"])], ' +
            'swiftLanguageModes: [' + language_mode + '])\n')
        environment = os.environ.copy()
        environment['FRUITFOLIO_TEST_OBSTACLE_MASKS_PATH'] = str(root / 'Fruitfolio/Fruit Basket/Prompt28ObstacleMasks.json')
        environment['FRUITFOLIO_TEST_RESEARCH_PATH'] = str(root / 'Fruitfolio/FruitfolioResearchPackage.json')
        environment['FRUITFOLIO_TEST_MODEL_PATH'] = str(root / 'FruitfolioAI.gguf')
        environment['CLANG_MODULE_CACHE_PATH'] = str(work / 'module-cache')
        environment['SWIFTPM_MODULECACHE_OVERRIDE'] = str(work / 'module-cache')
        environment['XDG_CACHE_HOME'] = str(work / 'xdg-cache')
        environment['XDG_CONFIG_HOME'] = str(work / 'xdg-config')
        # Swift 6.2.1's batched frontend can diagnose an inferred nonisolated
        # initializer on the unchanged cycle actor when DEBUG fixture files move
        # primary-file boundaries. The same complete sources typecheck and emit
        # a library unbatched. Keep every real source/test; disable batching only.
        return subprocess.run([args.swift, 'test', '-Xswiftc', '-disable-batch-mode', '--jobs', '2',
                               '--cache-path', str(work / 'cache'),
                               '--config-path', str(work / 'configuration'),
                               '--security-path', str(work / 'security')] +
                              (['--filter', args.test_filter] if args.test_filter else []),
                              cwd=work, env=environment).returncode

if __name__ == '__main__':
    raise SystemExit(main())
