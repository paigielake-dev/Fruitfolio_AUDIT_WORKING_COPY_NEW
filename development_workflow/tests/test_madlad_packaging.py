import importlib.util
from pathlib import Path
import unittest

MODULE = Path(__file__).resolve().parents[2] / 'Tools/prepare_madlad_manifest.py'
spec = importlib.util.spec_from_file_location('madlad_packaging', MODULE)
packaging = importlib.util.module_from_spec(spec)
spec.loader.exec_module(packaging)

class MADLADPackagingTests(unittest.TestCase):
    def metadata(self, **overrides):
        values = dict(model_name='MADLAD400.gguf', checksum='a' * 64, revision='b' * 40,
                      config={'model_type': 't5'}, architecture='t5', tokenizer='t5',
                      tokens=['<2en>', '<2es>', '<2sm>', '<2to>', 'ordinary', '<2unsupported tag>'], context_length=512)
        values.update(overrides)
        return values
    def test_coverage_comes_only_from_actual_fixture_vocabulary(self):
        manifest = packaging.manifest_from_metadata(**self.metadata())
        self.assertEqual(manifest['supportedLanguageTags'], ['en', 'es', 'sm', 'to'])
        self.assertNotIn('mh', manifest['supportedLanguageTags'])
    def test_decoder_only_or_unpinned_sources_are_rejected(self):
        for overrides in [{'architecture': 'qwen2'}, {'revision': 'main'}, {'tokens': ['ordinary']},
                          {'config': {'model_type': 'llama'}}, {'context_length': 0}]:
            with self.assertRaises(ValueError):
                packaging.manifest_from_metadata(**self.metadata(**overrides))

if __name__ == '__main__':
    unittest.main()
