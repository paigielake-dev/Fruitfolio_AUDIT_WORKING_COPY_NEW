import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('updates', Path(__file__).parents[1] / 'manage_research_snapshot.py')
u = importlib.util.module_from_spec(spec); spec.loader.exec_module(u)


def fixture(version='test-v1'):
    # Non-medical synthetic content is confined to the tooling test, never installed.
    package = dict(schemaVersion=1, contentVersion=version, generatedFrom='synthetic tooling fixture', generationNote='Not medical research',
                   sources=[dict(sourceID='source-stable', title='Synthetic fixture', sourceVersion='source-v1', contentVersion='test-v1', verificationStatus='verified', retrievalEligibility=True, apa7Reference='Synthetic fixture. (n.d.). Test only.', publicationDate=None, publicationType='Test fixture')],
                   researchNoteChunks=[dict(chunkID='note-stable', researchTopicID='topic-stable', heading='Fixture', subheading=None, text='A synthetic paragraph for testing immutable local snapshots.', sourceIDs=['source-stable'], semanticTags=[], domainTags=[])],
                   sourceChunks=[])
    return package


def proposal(package):
    raw = u.json_bytes(package)
    manifest = dict(schemaVersion=1, packageSHA256=u.digest(raw), supportedTopicIDs=['topic-stable'], retiredIDs={})
    # This test receipt is not production approval or a medical-review identity.
    review = dict(packageSHA256=u.digest(raw), founderApproved=True, scientificReviewApproved=True,
                  reviewer='Synthetic test reviewer', qualifications='Fixture only', reviewedAt='2026-11-02', scope='Fixture only', evidenceAssessment='No clinical content', revisionReason='Test')
    return raw, manifest, review


class ResearchUpdatesTests(unittest.TestCase):
    def test_valid_update_atomic_activation_rollback_and_historical_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            original = proposal(fixture())
            first = u.publish(root, *original)
            second_package = fixture('test-v2')
            second_package['researchNoteChunks'][0]['text'] = 'A corrected synthetic paragraph; old saved facts must not change.'
            second = u.publish(root, *proposal(second_package))
            self.assertNotEqual(first['activeSHA256'], second['activeSHA256'])
            self.assertEqual(u.snapshot(root, first['activeSHA256']), original[0])
            self.assertEqual(u.decode(u.snapshot(root, second['activeSHA256']))['researchNoteChunks'][0]['chunkID'], 'note-stable')
            reverted = u.rollback(root)
            self.assertEqual(reverted['activeSHA256'], first['activeSHA256'])
            self.assertEqual(u.snapshot(root, reverted['activeSHA256']), original[0])

    def test_invalid_update_and_failed_review_leave_active_bytes_unchanged(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); u.publish(root, *proposal(fixture()))
            state = (root/'CURRENT.json').read_bytes()
            malformed = fixture('test-v2'); malformed['researchNoteChunks'][0]['sourceIDs'] = ['missing']
            with self.assertRaises(u.Rejected): u.publish(root, *proposal(malformed))
            raw, manifest, review = proposal(fixture('test-v2')); review['scientificReviewApproved'] = False
            with self.assertRaises(u.Rejected): u.publish(root, raw, manifest, review)
            review['scientificReviewApproved'] = True; review['packageSHA256'] = '0' * 64
            with self.assertRaises(u.Rejected): u.publish(root, raw, manifest, review)
            self.assertEqual((root/'CURRENT.json').read_bytes(), state)

    def test_duplicate_ids_topics_source_versions_and_undeclared_retirement_rejected(self):
        base = fixture()
        variants = []
        duplicate = fixture('test-v2'); duplicate['researchNoteChunks'] *= 2; variants.append(duplicate)
        topic = fixture('test-v2'); topic['researchNoteChunks'][0]['researchTopicID'] = 'unknown'; variants.append(topic)
        source = fixture('test-v2'); source['sources'][0]['apa7Reference'] = 'Changed citation.'; variants.append(source)
        retirement = fixture('test-v2'); retirement['researchNoteChunks'] = []; retirement['sourceChunks'] = [dict(sourceChunkID='new-source-chunk', sourceID='source-stable', text='Synthetic backup passage', claimCategories=[])]; variants.append(retirement)
        for package in variants:
            with self.subTest(package=package):
                raw, manifest, _ = proposal(package)
                with self.assertRaises(u.Rejected): u.validate(raw, manifest, base)

    def test_corrupt_archived_snapshot_fails_without_activating_another_version(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); state = u.publish(root, *proposal(fixture()))
            pointer = (root/'CURRENT.json').read_bytes()
            (root/'snapshots'/state['activeSHA256']/'package.json').write_bytes(b'{corrupt')
            with self.assertRaises(u.Rejected): u.snapshot(root, state['activeSHA256'])
            self.assertEqual((root/'CURRENT.json').read_bytes(), pointer)

    def test_duplicate_json_keys_cannot_silently_override_content(self):
        with self.assertRaises(u.Rejected): u.decode(b'{"schemaVersion":1,"schemaVersion":2}')

    def test_package_install_is_exact_and_never_edits_gameplay_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); original = proposal(fixture()); state = u.publish(root, *original)
            game = root/'Gameplay.swift'; game.write_bytes(b'unchanged game source')
            output = root/'FruitfolioResearchPackage.json'
            u.atomic_write(output, u.snapshot(root, state['activeSHA256']))
            self.assertEqual(output.read_bytes(), original[0])
            self.assertEqual(game.read_bytes(), b'unchanged game source')

if __name__ == '__main__': unittest.main()
