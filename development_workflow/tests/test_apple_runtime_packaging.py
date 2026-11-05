import importlib.util
from pathlib import Path
import plistlib
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[2] / 'Tools/verify_apple_runtime.py'
spec = importlib.util.spec_from_file_location('apple_runtime', MODULE)
runtime = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runtime)

class AppleRuntimePackagingTests(unittest.TestCase):
    def library(self, name, variant=None):
        entry = dict(LibraryIdentifier=name, LibraryPath='llama.framework', SupportedPlatform='ios', SupportedArchitectures=['arm64'])
        if variant:
            entry['SupportedPlatformVariant'] = variant
        return entry
    def fixture(self, root, libraries):
        for library in libraries:
            (root / library['LibraryIdentifier'] / library['LibraryPath']).mkdir(parents=True)
        (root / 'Info.plist').write_bytes(plistlib.dumps({'AvailableLibraries': libraries}))
    def test_simulator_only_metadata_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.fixture(root, [self.library('ios-arm64-simulator', 'simulator')])
            with self.assertRaisesRegex(ValueError, 'Both iOS'):
                runtime.inspect(root)
    def test_device_and_simulator_metadata_is_recognized(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.fixture(root, [self.library('ios-arm64'), self.library('ios-arm64-simulator', 'simulator')])
            self.assertEqual(runtime.inspect(root), {'device', 'simulator'})
            # Metadata fixture only: this does not validate binary linking/inference.
    def test_declared_missing_artifact_is_rejected(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'Info.plist').write_bytes(plistlib.dumps({'AvailableLibraries': [self.library('missing')]}))
            with self.assertRaisesRegex(ValueError, 'missing'):
                runtime.inspect(root)

if __name__ == '__main__':
    unittest.main()
