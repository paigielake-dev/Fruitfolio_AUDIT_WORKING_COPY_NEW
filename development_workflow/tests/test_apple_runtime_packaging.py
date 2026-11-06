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

    def test_simulator_only_is_allowed_for_explicit_matching_simulator_test_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.fixture(root, [self.library('ios-arm64-simulator', 'simulator')])
            self.assertEqual(runtime.inspect(root, required={'simulator'}, simulator_architecture='arm64'), {'simulator'})
            with self.assertRaisesRegex(ValueError, 'Both iOS'):
                runtime.inspect(root)  # Strict release gate remains the default.

    def test_simulator_test_requires_actual_requested_architecture(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.fixture(root, [self.library('ios-arm64-simulator', 'simulator')])
            with self.assertRaisesRegex(ValueError, 'x86_64'):
                runtime.inspect(root, required={'simulator'}, simulator_architecture='x86_64')

    def test_device_only_target_cannot_accept_a_simulator_slice(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            self.fixture(root, [self.library('ios-arm64-simulator', 'simulator')])
            with self.assertRaisesRegex(ValueError, 'device'):
                runtime.inspect(root, required={'device'})
            self.fixture(root, [self.library('ios-arm64')])
            self.assertEqual(runtime.inspect(root, required={'device'}), {'device'})

    def test_invalid_or_empty_target_cannot_disable_checks(self):
        with tempfile.TemporaryDirectory() as temporary:
            for required in [set(), {'macos'}]:
                with self.assertRaisesRegex(ValueError, 'coverage'):
                    runtime.inspect(Path(temporary), required=required)

    def test_escaping_artifact_remains_rejected_for_simulator_target(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            entry = self.library('ios-arm64-simulator', 'simulator')
            entry['LibraryPath'] = '../../outside.framework'
            (root / 'Info.plist').write_bytes(plistlib.dumps({'AvailableLibraries': [entry]}))
            with self.assertRaisesRegex(ValueError, 'escaping'):
                runtime.inspect(root, required={'simulator'})

if __name__ == '__main__':
    unittest.main()
