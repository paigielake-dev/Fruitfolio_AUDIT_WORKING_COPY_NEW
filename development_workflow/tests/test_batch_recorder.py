import json
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
