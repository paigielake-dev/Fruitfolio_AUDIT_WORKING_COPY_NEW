import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

RECORDER = Path(__file__).resolve().parents[2] / 'Tools/record_prompt1b_batch.py'

class BatchRecorderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='fruitfolio-recorder-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.workflow = self.root / 'development_workflow'
        self.workflow.mkdir()
        (self.workflow / 'RUN_LOGS').mkdir()
        self.rows = [dict(sequence=n, original_requirement_id=str(n), original_checklist_part=f'Part {1 if n <= 70 else 2} — fixture section', description=f'Original {n}',
            implementation_status='NOT_STARTED', verification_status='NOT_RUN',
            relevant_source_files=[], related_tests=[], evidence_of_implementation=[]) for n in range(1,479)]
        (self.workflow / 'MASTER_CHECKLIST.json').write_text(json.dumps({'requirements':self.rows}))
        (self.workflow / 'CURRENT_CHECKPOINT.json').write_text('{}')
        (self.workflow / 'VERIFICATION_REGISTER.json').write_text('{}')
        (self.workflow / 'IMPLEMENTATION_LOG.md').write_text('Original log\n')
        subprocess.run(['git','init','-q'],cwd=self.root,check=True)
        subprocess.run(['git','-c','user.name=Fixture','-c','user.email=fixture@example.invalid',
            'commit','--allow-empty','-q','-m','fixture'],cwd=self.root,check=True)
        self.batch = dict(batch='fixture', requirements=[59], files=['actual.swift'], tests=['actualTests.swift'],
            summary='Implemented specific source behavior.', next_requirement=63, next='Verify next requirement.',
            commands=['actual command'], results={'workflow':1}, verification={
                'executed':{'Foundation':'passed'}, 'not_run':['Apple UI test'],
                'remaining':['Apple rendered behavior and all other original requirement paths']})
    def run_recorder(self):
        manifest=self.root/'manifest.json';manifest.write_text(json.dumps(self.batch))
        return subprocess.run(['python3',str(RECORDER),'--root',str(self.root),'--batch',str(manifest)],
            capture_output=True,text=True)
    def snapshots(self):
        return {p.name:p.read_bytes() for p in self.workflow.glob('*') if p.is_file()}
    def testActualRecorderPreservesOriginalsAndRecordsExecutionGapsOnlyForTargetedRows(self):
        result=self.run_recorder();self.assertEqual(result.returncode,0,result.stderr)
        rows=json.loads((self.workflow/'MASTER_CHECKLIST.json').read_text())['requirements']
        for before,after in zip(self.rows,rows):
            self.assertEqual(before['sequence'],after['sequence'])
            self.assertEqual(before['original_requirement_id'],after['original_requirement_id'])
            self.assertEqual(before['description'],after['description'])
            if before['sequence']!=59:self.assertEqual(before,after)
        row=rows[58];self.assertEqual(row['implementation_status'],'IN_PROGRESS')
        self.assertEqual(row['verification_status'],'SOURCE_REVIEWED')
        self.assertEqual(row['latest_batch_verification']['not_run'],['Apple UI test'])
        self.assertEqual(row['remaining_verification_requirements'],self.batch['verification']['remaining'])
        checkpoint=json.loads((self.workflow/'CURRENT_CHECKPOINT.json').read_text())
        self.assertEqual(checkpoint['last_batch_verification'],self.batch['verification'])
        log=json.loads((self.workflow/'RUN_LOGS/fixture.json').read_text())
        self.assertEqual(log['verification'],self.batch['verification'])
    def testInvalidOrDuplicateRequirementIDsCannotPartiallyWriteRecoveryFiles(self):
        before=self.snapshots()
        for ids in [[0],[479],[59,59],[True],['59'],[]]:
            self.batch['requirements']=ids
            self.assertNotEqual(self.run_recorder().returncode,0)
            self.assertEqual(self.snapshots(),before)
    def testMissingExplicitVerificationCannotAdvanceCheckpoint(self):
        before=self.snapshots()
        for key in ['executed','not_run','remaining']:
            original=self.batch['verification'].pop(key)
            self.assertNotEqual(self.run_recorder().returncode,0)
            self.assertEqual(self.snapshots(),before)
            self.batch['verification'][key]=original

    def testRepeatedBatchCannotOverwriteEvidenceOrAdvanceRecovery(self):
        self.assertEqual(self.run_recorder().returncode,0)
        before=self.snapshots()
        log=(self.workflow/'RUN_LOGS/fixture.json').read_bytes()
        self.assertNotEqual(self.run_recorder().returncode,0)
        self.assertEqual(self.snapshots(),before)
        self.assertEqual((self.workflow/'RUN_LOGS/fixture.json').read_bytes(),log)

    def testDistinctPerEntryEvidenceDoesNotSpreadUnrelatedSourceOrTestClaims(self):
        self.batch['requirements']=[59,63]
        specific={'summary':'Specific serious-context source change.', 'files':['serious.swift'],
            'tests':['seriousUITests.swift'], 'verification':{'executed':{'inspection':'source only'},
            'not_run':['serious Apple UI'], 'remaining':['actual serious rendering']}}
        self.batch['entry_evidence']={'59':specific}
        result=self.run_recorder();self.assertEqual(result.returncode,0,result.stderr)
        rows=json.loads((self.workflow/'MASTER_CHECKLIST.json').read_text())['requirements']
        self.assertEqual(rows[58]['relevant_source_files'],['serious.swift'])
        self.assertEqual(rows[58]['related_tests'],['seriousUITests.swift'])
        self.assertEqual(rows[58]['remaining_verification_requirements'],['actual serious rendering'])
        self.assertEqual(rows[62]['relevant_source_files'],['actual.swift'])
        self.assertEqual(rows[62]['latest_batch_verification']['not_run'],['Apple UI test'])
    def testUnscopedOrIncompletePerEntryEvidenceCannotWriteAnyRecoveryRecord(self):
        before=self.snapshots()
        for entries in [{'63':{}},{'59':{'summary':'missing verification'}}]:
            self.batch['entry_evidence']=entries
            self.assertNotEqual(self.run_recorder().returncode,0)
            self.assertEqual(self.snapshots(),before)

    def testRecoverySectionComesFromNextOriginalRequirementAcrossPartTransition(self):
        self.batch['part'] = 1
        self.batch['next_requirement'] = 71
        result = self.run_recorder()
        self.assertEqual(result.returncode, 0, result.stderr)
        checkpoint = json.loads((self.workflow / 'CURRENT_CHECKPOINT.json').read_text())
        self.assertEqual(checkpoint['current_checklist_part'], 2)
        self.assertEqual(checkpoint['current_checklist_section'], 'Part 2 — fixture section')
        self.assertEqual(checkpoint['last_recorded_batch_part'], 1)
        self.assertEqual(checkpoint['current_requirement'], 71)

    def testMissingOriginalNextSectionCannotPartiallyWriteRecoveryRecords(self):
        master = self.workflow / 'MASTER_CHECKLIST.json'
        rows = json.loads(master.read_text())
        rows['requirements'][62].pop('original_checklist_part')
        master.write_text(json.dumps(rows))
        before = self.snapshots()
        self.assertNotEqual(self.run_recorder().returncode, 0)
        self.assertEqual(self.snapshots(), before)

    def add_supplement(self):
        repo = RECORDER.parents[1]
        document = json.loads((repo / 'development_workflow/SUPPLEMENTAL_SPEC_CHECKLIST.json').read_text())
        path = self.workflow / 'SUPPLEMENTAL_SPEC_CHECKLIST.json'
        path.write_text(json.dumps(document))
        source = self.root / document['source']
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes((repo / document['source']).read_bytes())
        return document, path

    def testSupplementalEvidenceIsScopedAndBlockedAcceptanceCannotBePromoted(self):
        before, path = self.add_supplement()
        self.batch['supplemental_requirements'] = ['SPEC-7.9.6', 'SPEC-7.9.12']
        specific = {'summary': 'Mechanical fixture only, not official acceptance.',
            'files': ['unique-founder-fixture.swift'], 'tests': ['unique-founder-test.swift'],
            'verification': {'executed': {'synthetic': 1}, 'not_run': ['official model'],
                             'remaining': ['official weights and Apple device acceptance']}}
        self.batch['supplemental_entry_evidence'] = {'SPEC-7.9.12': specific}
        result = self.run_recorder(); self.assertEqual(result.returncode, 0, result.stderr)
        after = json.loads(path.read_text())
        for old, row in zip(before['requirements'], after['requirements']):
            for key in ['id', 'description', 'description_sha256', 'source_start_line', 'source_end_line']:
                self.assertEqual(old[key], row[key])
            if row['id'] not in self.batch['supplemental_requirements']:
                self.assertEqual(old, row)
        rows = {row['id']: row for row in after['requirements']}
        blocked = rows['SPEC-7.9.12']
        old = next(row for row in before['requirements'] if row['id'] == blocked['id'])
        self.assertEqual(blocked['implementation_status'], old['implementation_status'])
        self.assertEqual(blocked['blockers'], old['blockers'])
        self.assertEqual(blocked['latest_batch_verification']['executed'], {'synthetic': 1})
        self.assertEqual(blocked['remaining_verification_requirements'], specific['verification']['remaining'])
        self.assertIn('unique-founder-fixture.swift', blocked['relevant_source_files'])
        self.assertNotIn('unique-founder-fixture.swift', rows['SPEC-7.9.6']['relevant_source_files'])
        self.assertEqual(rows['SPEC-7.9.6']['batch_evidence'][-1]['implementation_evidence'], self.batch['summary'])
        checkpoint = json.loads((self.workflow/'CURRENT_CHECKPOINT.json').read_text())
        self.assertEqual(checkpoint['last_supplemental_requirements'], self.batch['supplemental_requirements'])
        run = json.loads((self.workflow/'RUN_LOGS/fixture.json').read_text())
        self.assertEqual(run['requirements'], [59])
        self.assertEqual(run['supplemental_requirements'], self.batch['supplemental_requirements'])

    def testInvalidSupplementalIDsCannotPartiallyUpdateOriginalOrRecoveryRecords(self):
        self.add_supplement()
        before = self.snapshots()
        for identifiers in [['SPEC-missing'], ['SPEC-7.9.6', 'SPEC-7.9.6'], [True], [123], [[]]]:
            self.batch['supplemental_requirements'] = identifiers
            self.assertNotEqual(self.run_recorder().returncode, 0)
            self.assertEqual(self.snapshots(), before)
            self.assertFalse((self.workflow/'RUN_LOGS/fixture.json').exists())

    def testUnscopedOrIncompleteSupplementalEvidenceCannotPartiallyWrite(self):
        self.add_supplement()
        before = self.snapshots()
        self.batch['supplemental_requirements'] = ['SPEC-7.9.6']
        for entries in [{'SPEC-7.9.12': {}}, {'SPEC-7.9.6': {'summary': 'missing verification'}}]:
            self.batch['supplemental_entry_evidence'] = entries
            self.assertNotEqual(self.run_recorder().returncode, 0)
            self.assertEqual(self.snapshots(), before)

    def testChangedFounderIdentityCannotBeAcceptedAsAnEvidenceUpdate(self):
        original, path = self.add_supplement()
        self.batch['supplemental_requirements'] = ['SPEC-7.9.6']
        for mutation in ['description', 'source-hash', 'order', 'outside-source']:
            doc = json.loads(json.dumps(original))
            if mutation == 'description': doc['requirements'][0]['description'] += ' changed'
            elif mutation == 'source-hash': doc['source_sha256'] = '0'*64
            elif mutation == 'order': doc['requirements'].reverse()
            else: doc['source'] = '/outside-repository-source'
            path.write_text(json.dumps(doc))
            before = self.snapshots()
            self.assertNotEqual(self.run_recorder().returncode, 0)
            self.assertEqual(self.snapshots(), before)

    def testSourceIndexRegenerationPreservesStructuredFounderEvidence(self):
        document, path = self.add_supplement()
        document['opaque_future_metadata'] = {'retain': None}
        document['requirements'][34]['opaque_future_progress'] = ['retain', {'null': None}]
        path.write_text(json.dumps(document))
        self.batch['supplemental_requirements'] = ['SPEC-7.9.6']
        result = self.run_recorder(); self.assertEqual(result.returncode, 0, result.stderr)
        before = json.loads(path.read_text())['requirements']
        sync = RECORDER.with_name('sync_supplemental_spec.py')
        result = subprocess.run(['python3', str(sync), '--root', str(self.root)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(path.read_text())['requirements'], before)
        self.assertEqual(json.loads(path.read_text())['opaque_future_metadata'], {'retain': None})
        result = subprocess.run(['python3', str(sync), '--root', str(self.root), '--check'], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def testBlockedOriginalRequirementKeepsItsExternalStatusWhileReceivingEvidence(self):
        path = self.workflow / 'MASTER_CHECKLIST.json'
        doc = json.loads(path.read_text())
        row = doc['requirements'][58]
        row['implementation_status'] = 'BLOCKED'; row['blockers'] = ['external source missing']
        path.write_text(json.dumps(doc))
        result = self.run_recorder(); self.assertEqual(result.returncode, 0, result.stderr)
        row = json.loads(path.read_text())['requirements'][58]
        self.assertEqual(row['implementation_status'], 'BLOCKED')
        self.assertEqual(row['verification_status'], 'NOT_RUN')
        self.assertEqual(row['blockers'], ['external source missing'])
        self.assertEqual(row['latest_batch_verification']['executed'], self.batch['verification']['executed'])

    def testWrongStructuredRecoveryShapesFailBeforeAnyChecklistPublication(self):
        for name, value in [('CURRENT_CHECKPOINT.json', []), ('VERIFICATION_REGISTER.json', {'batches': {}})]:
            path = self.workflow / name
            saved = path.read_bytes()
            path.write_text(json.dumps(value))
            before = self.snapshots()
            self.assertNotEqual(self.run_recorder().returncode, 0)
            self.assertEqual(self.snapshots(), before)
            path.write_bytes(saved)

    def testVerificationGapEntriesMustBeExplicitTextBeforeAnyPublication(self):
        before = self.snapshots()
        for key in ['not_run', 'remaining']:
            original = self.batch['verification'][key]
            self.batch['verification'][key] = [123]
            self.assertNotEqual(self.run_recorder().returncode, 0)
            self.assertEqual(self.snapshots(), before)
            self.batch['verification'][key] = original

    def testSupplementalRecordingDoesNotCreateParserBytecodeInTheCheckout(self):
        self.add_supplement()
        self.batch['supplemental_requirements'] = ['SPEC-7.9.6']
        tools = self.root / 'Tools'; tools.mkdir()
        copied = tools / RECORDER.name
        copied.write_bytes(RECORDER.read_bytes())
        (tools / 'sync_supplemental_spec.py').write_bytes(RECORDER.with_name('sync_supplemental_spec.py').read_bytes())
        manifest = self.root / 'manifest.json'; manifest.write_text(json.dumps(self.batch))
        environment = os.environ.copy(); environment.pop('PYTHONDONTWRITEBYTECODE', None)
        result = subprocess.run(['python3', str(copied), '--root', str(self.root), '--batch', str(manifest)],
            capture_output=True, text=True, env=environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(list(tools.rglob('*.pyc')))
