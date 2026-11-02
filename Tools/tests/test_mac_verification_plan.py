import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('verify_integrated_source_on_mac', ROOT / 'Tools/verify_integrated_source_on_mac.py')
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class FounderMacPlanSafetyTests(unittest.TestCase):
    def testEveryExecutableGroupExcludesTheDeferredInferenceClass(self):
        for group in ['build', *runner.GROUPS]:
            command = runner.commands(group, 'observed-simulator', Path('/tmp/fruitfolio-evidence'))
            self.assertIn('-skip-testing:FruitfolioTests/AAAA_MADLADRuntimeIntegrationTests', command)
            self.assertFalse(any('only-testing:FruitfolioTests/AAAA_MADLAD' in value for value in command))

    def testCoreBatchSeparatesActualNativeInferenceFromOrdinaryUnitCoverage(self):
        command = runner.commands('unit', 'observed-simulator', Path('/tmp/fruitfolio-evidence'))
        self.assertIn('-only-testing:FruitfolioTests', command)
        self.assertIn('-skip-testing:FruitfolioTests/BundledNativeGroundingTests', command)
        native = runner.commands('native', 'observed-simulator', Path('/tmp/fruitfolio-evidence'))
        self.assertIn('-only-testing:FruitfolioTests/BundledNativeGroundingTests', native)
        self.assertNotIn('-only-testing:FruitfolioTests', native)

    def testBuildIsNotAReportedTestExecutionAndEvidenceDestinationsAreExplicit(self):
        command = runner.commands('build', 'observed-simulator', Path('/tmp/fruitfolio-evidence'))
        self.assertEqual(command[:2], ['xcodebuild', 'build-for-testing'])
        self.assertIn('platform=iOS Simulator,id=observed-simulator', command)
        self.assertEqual(command[command.index('-resultBundlePath') + 1], '/tmp/fruitfolio-evidence/build.xcresult')


if __name__ == '__main__':
    unittest.main()
