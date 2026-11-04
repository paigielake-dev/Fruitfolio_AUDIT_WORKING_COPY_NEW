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



class ActualArchiveMechanicsTests(unittest.TestCase):
    def testIntegratedArchivePhysicallyExtractsAndBinaryPartsReconstructExactUTF8Files(self):
        from argparse import Namespace
        import contextlib
        import hashlib
        import io
        import json
        import os
        import tempfile
        from unittest.mock import patch
        import zipfile
        with tempfile.TemporaryDirectory() as directory:
            parent = Path(directory); root = parent / 'project'; root.mkdir()
            (root / 'Tools').mkdir(); (root / 'Tools/reconstruct_delivery.py').write_bytes((ROOT / 'Tools/reconstruct_delivery.py').read_bytes())
            project = root / 'Fruitfolio.xcodeproj/project.pbxproj'; project.parent.mkdir()
            project.write_text('// PBXProject miniature packaging fixture\n')
            scheme = root / 'Fruitfolio.xcodeproj/xcshareddata/xcschemes/Fruitfolio.xcscheme'
            scheme.parent.mkdir(parents=True); scheme.write_text('<Scheme></Scheme>\n')
            artwork_name = 'Original assets/莓 ♡ fixture.bin'
            artwork = root / artwork_name; artwork.parent.mkdir()
            original = os.urandom(1100000); artwork.write_bytes(original)
            args = Namespace(kind='integrated', source_commit='a' * 40, source_tree='b' * 40,
                             branch='fixture/development', output_directory=parent / 'delivery',
                             part_size_mib=1, verify_only=False)
            tracker = {'summary': {'NOT VERIFIED': 1}, 'requirements': [{'implementationStatus': 'NOT VERIFIED'}]}
            with patch.object(packager, 'ROOT', root), patch.object(packager, 'verify_inputs', return_value=tracker), contextlib.redirect_stdout(io.StringIO()):
                packager.package(args)
            output = args.output_directory
            index = json.loads((output / 'Fruitfolio_Prompt_1B_INTEGRATED_SOURCE.zip.parts.json').read_text())
            self.assertEqual(index['verification']['physicalExtractionAndFileReadback'], 'PASS')
            self.assertEqual(index['verification']['releaseAcceptance'], 'NOT CLAIMED')
            self.assertGreater(len(index['parts']), 1)
            combined = b''.join((output / part['name']).read_bytes() for part in index['parts'])
            self.assertEqual(hashlib.sha256(combined).hexdigest(), index['sha256'])
            with zipfile.ZipFile(io.BytesIO(combined)) as archive:
                self.assertIsNone(archive.testzip())
                self.assertEqual(archive.read(artwork_name), original)
                self.assertIn('Delivery/PackagedFileIntegrity.json', archive.namelist())
            import subprocess
            import sys
            archive_path = output / index['archive']
            archive_path.unlink()
            index_path = output / (index['archive'] + '.parts.json')
            helper = output / 'RECONSTRUCT_FRUITFOLIO.py'
            rebuilt = subprocess.run([sys.executable, str(helper), str(index_path)], capture_output=True, text=True)
            self.assertEqual(rebuilt.returncode, 0, rebuilt.stderr)
            self.assertEqual(hashlib.sha256(archive_path.read_bytes()).hexdigest(), index['sha256'])
            archive_path.unlink()
            (output / index['parts'][0]['name']).write_bytes(b'deliberately corrupt fixture part')
            rejected = subprocess.run([sys.executable, str(helper), str(index_path)], capture_output=True, text=True)
            self.assertNotEqual(rejected.returncode, 0)
            self.assertFalse(archive_path.exists(), 'Corrupt parts must never publish a reconstructed archive')


    def testFinalCompleteCannotBeProducedFromAnIncompleteTracker(self):
        with self.assertRaisesRegex(RuntimeError, 'FINAL_COMPLETE refused'):
            packager.final_gate({'requirements': [{'implementationStatus': 'PARTIAL'}]}, 'a' * 40)


if __name__ == '__main__':
    unittest.main()
