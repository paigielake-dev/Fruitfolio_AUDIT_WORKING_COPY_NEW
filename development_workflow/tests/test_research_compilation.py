import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('fruitfolio_research_compiler', ROOT / 'Tools/compile_research_package.py')
COMPILER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(COMPILER)

class ResearchCompilationTests(unittest.TestCase):
    def corpus(self, folder, rows):
        document = ET.Element(COMPILER.W + 'document')
        body = ET.SubElement(document, COMPILER.W + 'body')
        for style, text in rows:
            paragraph = ET.SubElement(body, COMPILER.W + 'p')
            properties = ET.SubElement(paragraph, COMPILER.W + 'pPr')
            ET.SubElement(properties, COMPILER.W + 'pStyle', {COMPILER.W + 'val': style})
            run = ET.SubElement(paragraph, COMPILER.W + 'r')
            ET.SubElement(run, COMPILER.W + 't').text = text
        path = Path(folder) / 'fixture.docx'
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr('word/document.xml', ET.tostring(document))
        return path

    def test_exact_chunks_and_references_survive_without_invented_scientific_sources(self):
        original = 'E2 20 pg/mL. uncertainty remains. μg — exact words. ' * 100
        reference = 'Organization. (2024). Exact original title. https://example.org/paper'
        with tempfile.TemporaryDirectory() as folder:
            path = self.corpus(folder, [('Title', 'FruitsofLife.xo Research Corpus'), ('Title', 'fixture topic'),
                                       ('Normal', original), ('Heading1', 'SOURCES'), ('Normal', reference)])
            package, report = COMPILER.compile_package(path)
        self.assertEqual(''.join(row['text'] for row in package['researchNoteChunks']), original)
        self.assertTrue(all(row['retrievalEligibility'] for row in package['researchNoteChunks']))
        self.assertEqual(package['sources'][0]['apa7Reference'], reference)
        self.assertEqual(package['sources'][0]['verificationStatus'], 'founderCorpusAPA7')
        self.assertIsNone(package['sources'][0]['verifiedAt'])
        self.assertEqual(package['sourceChunks'], [])
        for chunk in package['researchNoteChunks']:
            self.assertEqual(package['sourceParagraphs'][chunk['sourceParagraphID']], original)
        self.assertEqual(report['quarantinedTopics'], [])

    def test_ambiguous_references_and_lifebridge_are_preserved_but_not_retrievable(self):
        rows = [('Title', 'FruitsofLife.xo Research Corpus'), ('Title', 'ambiguous'), ('Normal', 'exact retained research'),
                ('Heading1', 'SOURCES'), ('Normal', 'unresolved source name without APA metadata'),
                ('Title', 'LifeBridge agency'), ('Normal', 'older organization claims'), ('Heading1', 'SOURCES'),
                ('Normal', 'LifeBridge. (2024). Original agency reference.')]
        with tempfile.TemporaryDirectory() as folder:
            package, report = COMPILER.compile_package(self.corpus(folder, rows))
        self.assertEqual(len(report['quarantinedTopics']), 2)
        self.assertFalse(package['sources'][0]['retrievalEligibility'])
        self.assertTrue(all(not row['retrievalEligibility'] for row in package['researchNoteChunks']))
        self.assertEqual([row['text'] for row in package['researchNoteChunks']], ['exact retained research', 'older organization claims'])

    def test_committed_package_is_reproducible_from_unchanged_original_assets(self):
        result = subprocess.run([sys.executable, str(ROOT / 'Tools/compile_research_package.py'), '--check'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads((ROOT / 'development_workflow/RESEARCH_PACKAGE_REPORT.json').read_text())
        self.assertGreater(report['eligibleNoteChunks'], 2000)
        self.assertEqual(report['fullSourceChunks'], 0)
