import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("package_final_delivery", ROOT / "Tools/package_final_delivery.py")
packager = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packager)


class StrictGroundingDeliveryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (ROOT / "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift").read_text()
        cls.guard = '        guard evidence.hasUnambiguousEvidenceIdentity else { return nil }\n'

    def testActualValidatorRetainsCompleteAuthoritativeRulesPlusStricterIdentityPreflight(self):
        result = packager.verify_strict_validator(self.source)
        self.assertEqual(result['originalValidatorSHA256'],
                         '18354af8a8f3349a21648a77778702d59a9c42539d77c64d5577afc355182b60')

    def testRemovingOrDuplicatingTheNewSafetyGuardFailsDelivery(self):
        for altered in [self.source.replace(self.guard, '', 1),
                        self.source.replace(self.guard, self.guard * 2, 1)]:
            with self.assertRaises(RuntimeError):
                packager.verify_strict_validator(altered)

    def testEvenAOneByteChangeToOriginalGroundingRulesFailsDelivery(self):
        altered = self.source.replace('nonisolated enum FruitfolioGeneratedDraftValidator {',
                                      'nonisolated enum FruitfolioGeneratedDraftValidator { ', 1)
        with self.assertRaises(RuntimeError):
            packager.verify_strict_validator(altered)


if __name__ == '__main__':
    unittest.main()
