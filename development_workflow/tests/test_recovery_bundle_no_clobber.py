import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('fruitfolio_recovery_tool', ROOT / 'Tools/create_local_recovery_bundle.py')
TOOL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(TOOL)


class RecoveryBundlePreservationTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix='fruitfolio-recovery-tests-')
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / 'repo'
        self.repo.mkdir()
        self.git('init', '-q', '-b', 'main')
        self.git('config', 'user.name', 'Fruitfolio Recovery Fixture')
        self.git('config', 'user.email', 'fixture@fruitfolio.invalid')
        self.git('config', 'core.hooksPath', '/dev/null')
        (self.repo / 'note.txt').write_text('base\n')
        self.git('add', 'note.txt')
        self.git('commit', '-q', '-m', 'base')
        self.base = self.git('rev-parse', 'HEAD')
        self.git('update-ref', 'refs/remotes/origin/main', self.base)
        self.git('switch', '-q', '-c', 'development/prompt-1b-complete')
        (self.repo / 'note.txt').write_text('checkpoint\n')
        self.git('commit', '-q', '-am', 'checkpoint')
        self.head = self.git('rev-parse', 'HEAD')
        self.output = self.root / 'recovery' / 'checkpoint.bundle'
        self.output.parent.mkdir()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args], text=True, stderr=subprocess.PIPE).strip()

    def testFreshBundleAndManifestVerifyAgainstRealGitTip(self):
        result = TOOL.create(self.repo, self.output)
        self.assertEqual(result['HEAD'], self.head)
        self.assertEqual(result['prerequisite_commit'], self.base)
        self.assertEqual(result['checkpoint_commits'], 1)
        self.assertEqual(result['sha256'], hashlib.sha256(self.output.read_bytes()).hexdigest())
        self.git('bundle', 'verify', str(self.output))
        self.assertEqual(json.loads(self.output.with_suffix('.bundle.json').read_text()), result)
        self.assertEqual(self.git('status', '--porcelain'), '')
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.head)

    def testExistingBundleIsRejectedAndRetainedByteForByte(self):
        original = b'previous recovery artifact: preserve exactly'
        self.output.write_bytes(original)
        with self.assertRaises(ValueError):
            TOOL.create(self.repo, self.output)
        self.assertEqual(self.output.read_bytes(), original)
        self.assertFalse(self.output.with_suffix('.bundle.json').exists())

    def testExistingSidecarIsRejectedWithoutCreatingOrOverwritingArtifacts(self):
        sidecar = self.output.with_suffix('.bundle.json')
        original = b'{"preserve":"existing manifest"}\n'
        sidecar.write_bytes(original)
        with self.assertRaises(ValueError):
            TOOL.create(self.repo, self.output)
        self.assertEqual(sidecar.read_bytes(), original)
        self.assertFalse(self.output.exists())

    def testExistingDeterministicTemporaryFileIsNeverUsedOrDeleted(self):
        previous = self.output.with_suffix('.bundle.tmp')
        original = b'previous interrupted recovery output'
        previous.write_bytes(original)
        TOOL.create(self.repo, self.output)
        self.assertEqual(previous.read_bytes(), original)
        self.git('bundle', 'verify', str(self.output))

    def testOutputSymlinkCannotOverwriteItsExistingTarget(self):
        protected = self.root / 'protected-original.bundle'
        original = b'preserve the symlink target'
        protected.write_bytes(original)
        self.output.symlink_to(protected)
        with self.assertRaises(ValueError):
            TOOL.create(self.repo, self.output)
        self.assertTrue(self.output.is_symlink())
        self.assertEqual(protected.read_bytes(), original)

    def testDestinationCreatedDuringPublicationIsNeverReplaced(self):
        original_link = TOOL.os.link
        sentinel = b'concurrent recovery output'
        def publish(source, destination):
            if Path(destination) == self.output:
                self.output.write_bytes(sentinel)
            return original_link(source, destination)
        with mock.patch.object(TOOL.os, 'link', side_effect=publish):
            with self.assertRaises(FileExistsError):
                TOOL.create(self.repo, self.output)
        self.assertEqual(self.output.read_bytes(), sentinel)
        self.assertFalse(self.output.with_suffix('.bundle.json').exists())
        self.assertEqual(list(self.output.parent.glob('*.owned-*.tmp')), [])

    def testSidecarPublicationRacePreservesForeignSidecarAndVerifiedBundle(self):
        original_link = TOOL.os.link
        sidecar = self.output.with_suffix('.bundle.json')
        sentinel = b'{"concurrent":"manifest preserved"}'
        def publish(source, destination):
            if Path(destination) == sidecar:
                sidecar.write_bytes(sentinel)
            return original_link(source, destination)
        with mock.patch.object(TOOL.os, 'link', side_effect=publish):
            with self.assertRaises(FileExistsError):
                TOOL.create(self.repo, self.output)
        self.assertEqual(sidecar.read_bytes(), sentinel)
        self.git('bundle', 'verify', str(self.output))
        self.assertIn(self.head, self.git('bundle', 'list-heads', str(self.output)))
        self.assertEqual(list(self.output.parent.glob('*.owned-*.tmp')), [])

    def testCLIReportsPreservationFailureWithoutSuccessJSONOrArtifactChanges(self):
        sentinel = b'earlier checkpoint retained'
        self.output.write_bytes(sentinel)
        result = subprocess.run([sys.executable, str(ROOT / 'Tools/create_local_recovery_bundle.py'),
            '--repo', str(self.repo), '--output', str(self.output)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(result.stdout, '')
        self.assertIn('Existing artifacts were preserved', result.stderr)
        self.assertEqual(self.output.read_bytes(), sentinel)
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.head)
