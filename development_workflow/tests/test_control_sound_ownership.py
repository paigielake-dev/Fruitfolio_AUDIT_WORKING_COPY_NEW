"""Exercise the real SwiftSyntax codemod; these are not playback tests."""
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ControlSoundOwnershipTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        compiler = os.environ.get('FRUITFOLIO_SWIFTC') or shutil.which('swiftc')
        if not compiler:
            raise unittest.SkipTest('Swift compiler with host SwiftSyntax is unavailable')
        host = Path(compiler).resolve().parent.parent / 'lib/swift/host'
        if not (host / 'SwiftParser.swiftmodule').is_dir():
            raise unittest.SkipTest('Toolchain host SwiftParser is unavailable')
        cls.work = tempfile.TemporaryDirectory(prefix='fruitfolio-sound-tool-')
        cls.addClassCleanup(cls.work.cleanup)
        cls.binary = Path(cls.work.name) / 'control-sounds'
        command = [compiler, '-parse-as-library', '-module-cache-path', str(Path(cls.work.name) / 'cache'),
                   '-I', str(host), '-L', str(host), '-lSwiftSyntax', '-lSwiftParser',
                   '-Xlinker', '-rpath', '-Xlinker', str(host),
                   str(ROOT / 'Tools/normalize_control_sound_ownership.swift'), '-o', str(cls.binary)]
        result = subprocess.run(command, capture_output=True, text=True)
        if result.returncode:
            raise AssertionError(result.stderr)

    def invoke(self, path, mode=None, extra=()):
        command = [str(self.binary)] + ([mode] if mode else []) + [str(path)] + list(map(str, extra))
        return subprocess.run(command, capture_output=True, text=True)

    def testChecksAndApplyAreDistinctAndRetryIsClean(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'sample.swift'
            path.write_text('WatercolorSecondaryButton(label: "save") {\n audioManager.play(.buttonSoftPop)\n save()\n}\n')
            original = path.read_bytes()
            check = self.invoke(path, '--check')
            self.assertEqual(check.returncode, 1)
            self.assertEqual(path.read_bytes(), original)
            self.assertEqual(len(json.loads(check.stdout)), 1)
            self.assertEqual(self.invoke(path, '--apply').returncode, 0)
            self.assertIn('save()', path.read_text())
            self.assertNotIn('audioManager.play', path.read_text())
            self.assertEqual(self.invoke(path, '--check').returncode, 0)

    def testNestedRawButtonRetainsItsOnlyCue(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'nested.swift'
            path.write_text('WatercolorPrimaryButton(label: "outer") {\n audioManager.play(.buttonSoftPop)\n Button("raw") { audioManager.play(.buttonSoftPop) }\n}\n')
            result = self.invoke(path, '--apply')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(path.read_text().count('audioManager.play(.buttonSoftPop)'), 1)
            self.assertIn('Button("raw") { audioManager.play', path.read_text())

    def testCommentsStringsOtherCuesAndNoncanonicalButtonsAreUntouched(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'untouched.swift'
            source = '''// WatercolorSecondaryButton { audioManager.play(.buttonSoftPop) }
WatercolorSecondaryButton(label: "audioManager.play(.buttonSoftPop)") {
 audioManager.play(.popupClose)
 Button("raw") { audioManager.play(.buttonSoftPop) }
}
'''
            path.write_text(source)
            result = self.invoke(path, '--apply')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), [])
            self.assertEqual(path.read_text(), source)

    def testUTF8MultilineExplicitActionsAndPermissionsSurvive(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'utf8.swift'
            path.write_text('WatercolorSecondaryButton(label: "naïve 🌿", action: {\n // retain this explanation\n audioManager.play(\n  .buttonSoftPop\n )\n finish()\n})\n')
            path.chmod(0o640)
            result = self.invoke(path, '--apply')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('naïve 🌿', path.read_text())
            self.assertIn('// retain this explanation', path.read_text())
            self.assertIn('finish()', path.read_text())
            self.assertNotIn('.buttonSoftPop', path.read_text())
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o640)

    def testMalformedSecondFileCannotPartiallyRewriteFirst(self):
        with tempfile.TemporaryDirectory() as folder:
            first, bad = Path(folder) / 'first.swift', Path(folder) / 'bad.swift'
            first.write_text('WatercolorPrimaryButton(label: "x") { audioManager.play(.buttonSoftPop); action() }\n')
            bad.write_text('WatercolorSecondaryButton(')
            original = first.read_bytes()
            result = self.invoke(first, '--apply', [bad])
            self.assertEqual(result.returncode, 2)
            self.assertIn('no source modified', result.stderr)
            self.assertEqual(first.read_bytes(), original)

    def testSemicolonItemRemovalPreservesOtherStatementAndInlineComment(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'semicolon.swift'
            path.write_text('CloseControl { audioManager.play(.buttonSoftPop); action() }\nBackControl {\n audioManager.play(.buttonSoftPop) // keep note\n back()\n}\n')
            result = self.invoke(path, '--apply')
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('action()', path.read_text())
            self.assertIn('// keep note', path.read_text())
            self.assertIn('back()', path.read_text())
            self.assertNotIn('buttonSoftPop', path.read_text())
            self.assertEqual(self.invoke(path, '--check').returncode, 0)


if __name__ == '__main__':
    unittest.main()
