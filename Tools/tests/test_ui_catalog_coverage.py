"""Reconstituted lost catalog regression cases; source history retained in recovery notes."""
import importlib.util
from pathlib import Path
import unittest
spec = importlib.util.spec_from_file_location('catalog', Path(__file__).resolve().parents[1] / 'audit_ui_catalog_coverage.py')
catalog = importlib.util.module_from_spec(spec); spec.loader.exec_module(catalog)

class CatalogCoverageTests(unittest.TestCase):
    def test_blank_units_do_not_hide_missing_entries(self):
        data={'sourceLanguage':'en','strings':{'one':{'localizations':{'es':{'stringUnit':{'value':'  ','state':'translated'}}}}}}
        row=catalog.summarize(data,['es'])['languages'][0]
        self.assertEqual(row['declaredNonemptyEntries'],0);self.assertEqual(row['missingExplicitEntries'],1)
    def test_declared_translated_state_and_identity_values_do_not_establish_acceptance(self):
        data={'sourceLanguage':'en','strings':{'cancel':{'localizations':{'es':{'stringUnit':{'value':'cancel','state':'translated'}}}}}}
        row=catalog.summarize(data,['es'])['languages'][0]
        self.assertEqual(row['declaredNonemptyEntries'],1);self.assertEqual(row['entriesDifferentFromSource'],0)
        self.assertEqual(row['acceptanceStatus'],'NOT VERIFIED')
    def test_plural_units_count_as_one_key_and_keep_each_declared_state(self):
        data={'sourceLanguage':'en','strings':{'items':{'localizations':{'es':{'variations':{'plural':{
            'one':{'stringUnit':{'value':'uno','state':'translated'}},
            'other':{'stringUnit':{'value':'varios','state':'needs_review'}}}}}}}}}
        row=catalog.summarize(data,['es'])['languages'][0]
        self.assertEqual(row['declaredNonemptyEntries'],1)
        self.assertEqual(row['declaredUnitStates'],{'translated':1,'needs_review':1})
        self.assertEqual(row['acceptanceStatus'],'NOT VERIFIED')
