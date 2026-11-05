import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('fruitfolio_recovery_bundle', ROOT / 'Tools/create_local_recovery_bundle.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), '-c', 'user.name=Recovery Fixture',
                                   '-c', 'user.email=fixture@example.invalid', *args], text=True, stderr=subprocess.DEVNULL).strip()


class RecoveryBundleTests(unittest.TestCase):
    def test_checkpoint_restores_into_repository_that_has_only_prerequisite_objects(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory); repo = base / 'source'; repo.mkdir()
            git(repo, 'init', '-b', 'main')
            (repo / 'source.txt').write_text('baseline')
            git(repo, 'add', 'source.txt'); git(repo, 'commit', '-m', 'baseline')
            prerequisite = git(repo, 'rev-parse', 'HEAD')
            git(repo, 'update-ref', 'refs/remotes/origin/main', prerequisite)
            branch = 'development/prompt-1b-complete'
            git(repo, 'switch', '-c', branch)
            (repo / 'source.txt').write_text('implemented checkpoint')
            git(repo, 'add', 'source.txt'); git(repo, 'commit', '-m', 'checkpoint')
            head = git(repo, 'rev-parse', 'HEAD')
            bundle = base / 'recovery' / 'checkpoint.bundle'
            manifest = MODULE.create(repo, bundle)
            self.assertEqual(manifest['HEAD'], head)
            restore = base / 'restore'; restore.mkdir(); git(restore, 'init')
            git(restore, 'fetch', '--no-tags', str(repo), prerequisite)
            missing = subprocess.run(['git', '-C', str(restore), 'cat-file', '-e', head], capture_output=True)
            self.assertNotEqual(missing.returncode, 0)
            git(restore, 'fetch', str(bundle), f'refs/heads/{branch}:refs/heads/{branch}')
            git(restore, 'switch', branch)
            self.assertEqual(git(restore, 'rev-parse', 'HEAD'), head)
            self.assertEqual((restore / 'source.txt').read_text(), 'implemented checkpoint')
            (repo / 'source.txt').write_text('pending changes must not disappear')
            with self.assertRaises(ValueError): MODULE.create(repo, base / 'dirty.bundle')
            self.assertEqual((repo / 'source.txt').read_text(), 'pending changes must not disappear')
