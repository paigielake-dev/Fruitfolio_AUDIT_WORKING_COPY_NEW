#!/usr/bin/env python3
"""Narrow criterion review against actual Run45, preserving all original IDs/history.

Pending source changes never inherit a previous runtime result. This tool does
not infer completeness from source presence or count a skipped test as PASS.
"""
import collections
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
path = root / 'Delivery/ImplementationTracker478.json'
data = json.loads(path.read_text())
records = {r['requirementID']: r for r in data['requirements']}
unit = 'Fruitfolio_Verification_Evidence/AppleRuns/Run45/UnitBuild/xcode-unit-test.log'
volumes = 'Fruitfolio_Verification_Evidence/AppleRuns/Run45/SettingsVolumes/Build/xcode-settings-volumes-ui-test.log'
username = 'Fruitfolio_Verification_Evidence/AppleRuns/Run45/UsernameJourney/Build/xcode-username-journey-ui-test.log'
pages = 'Fruitfolio_Verification_Evidence/AppleRuns/Run45/UserPages/Build/xcode-user-pages-ui-test.log'
commit = '884184040db65aef0f4fd28a5963509fd9501748'
current = '0435fa3679e43057f163929189ec845dffdbaf40'

def review(n, status, files, tests, evidence, change, remaining, section):
    r = records[f'FF1B-{n:03}']
    for p in files + evidence:
        assert (root / p).is_file(), p
    if status == 'PASS':
        logs = '\n'.join((root / p).read_text(errors='replace') for p in evidence if p.endswith('.log'))
        for test in tests:
            cls, name = test.split('/')
            assert f'{cls} {name}]\' passed (' in logs, test
    history = {'baseline': 'actual Run45 exact source ' + commit, 'status': r['implementationStatus']}
    if history not in r['historicalStatuses']: r['historicalStatuses'].append(history)
    r.update(implementationStatus=status, afterStatus=status, finalDisposition=status,
             implementationAssessment='ASSESSED', currentImplementationState='IMPLEMENTED' if status in ['PASS','NOT VERIFIED'] else 'PARTIALLY IMPLEMENTED',
             verificationState='PASS' if status=='PASS' else 'NOT TESTED' if status=='NOT VERIFIED' else 'INCONCLUSIVE',
             inspectionState='ALREADY IMPLEMENTED AND VERIFIED' if status=='PASS' else 'IMPLEMENTED BUT NOT VERIFIED' if status=='NOT VERIFIED' else 'PARTIALLY IMPLEMENTED',
             remainingIssues=remaining, missingImplementation=remaining)
    for key, values in [('relevantSourceFiles', files), ('testsPerformed', tests), ('supportingEvidence', evidence), ('changesMade', [change])]:
        r[key] = list(dict.fromkeys(r.get(key, []) + values))
    r['existingSourceFiles'] = [p for p in r['relevantSourceFiles'] if (root / p).is_file()]
    r['evidenceReferences'] = r['supportingEvidence']
    r['prompt1BSection'] = {'candidateSection': section, 'exactCrossReferenceStatus': 'Corresponding binding text reviewed; original breakdown reference retained'}
    r['sourceSection'] = r['prompt1BSection']
    r['testResults'] = [{'result': status, 'scope': 'Exact criterion only; earlier source runtime evidence does not verify pending new source',
                         'tests': tests, 'verifiedSourceCommits': [commit] if status=='PASS' else [], 'currentSourceCommit': current}]
    r['requiredAcceptanceTests'] = [{'criterion':r['originalBreakdownItem'], 'testIDs':tests, 'assessment':'Actual scoped runtime evidence or explicit pending new implementation'}]

volume_test = 'SettingsVolumeUITests/testOriginalArtworkControlsChangeIndependentlyAndPersistAfterRestart'
audio = 'Fruitfolio/Core/Assets/AudioManager.swift'
review(225,'PASS',[audio,'Fruitfolio/Privacy Settings/Prompt12SettingsView.swift'],
       [volume_test,'AudioLifecycleRuntimeTests/testActualMusicAndRainPlayersRemainIndependentAndSettingsMuteOnlyTheirCategory'],[unit,volumes],
       'Actual simulator toggles each category, preserves the other preferences, restarts, and restores; native AVAudioPlayer responds to the music preference.', [], '6B — Actual audio preference behavior')
review(226,'PASS',[audio],['AudioLifecycleRuntimeTests/testMasterMuteStopsActualPlayersAndOnlyResumesEnabledRequestedLoops',
       'AudioLifecycleRuntimeTests/testZeroVolumeActuallyStopsPlayersAndOnlyResumesRequestedEnabledLoops',
       'AudioLifecycleRuntimeTests/testCompletedFadeActuallyPausesTheLoopAndZeroDurationPausesImmediately',
       'AudioLifecycleRuntimeTests/testRapidReentryCancelsThePreviousFadePauseWithoutStoppingTheNewRequest'],[unit],
       'Actual native players stop/pause for master mute, disabled categories, zero volume, and completed fades; obsolete pauses do not stop a new request.',[], '6B — Muted, disabled and zero-volume playback')
for n in [230,231,463]:
    review(n,'PASS',['Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift','Fruitfolio/Privacy Settings/Prompt12AccountView.swift','Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift'],
           ['UsernameSynchronizationUITests/testOrdinaryTypingSynchronizesAccountAndFruitBasketAndSurvivesRestart'],[username],
           'Actual ordinary typing saves through Account, appears in Fruit Basket, edits there, appears back in Account, and survives app restart. This criterion concerns shared local identity; global reservation and real-name moderation remain separate unfinished requirements.',[], '6F / 19X — Shared Account and Fruit Basket username')
review(465,'PASS',[audio,'FruitfolioUITests/SettingsVolumeUITests.swift'],[volume_test,
       'AudioLifecycleRuntimeTests/testMasterMuteStopsActualPlayersAndOnlyResumesEnabledRequestedLoops'],[unit,volumes],
       'Actual preference interactions, persistence and player API behavior tested. Audible quality is not asserted.',[], '6B — Audio preferences and global mute tests')
review(455,'PARTIAL',['FruitfolioUITests/UserAuthoredPageUITests.swift'],
       ['UserAuthoredPageUITests/testCreateReopenEditAndDiscardUserPageThroughActualLibrary'],[pages],
       'Actual book creation, manual page writing, real Photos import, reopen, edit/discard, save/restart and confirmed page deletion PASS.',
       ['Full encyclopedia rename/recolour/delete, all alternate file/import and error states, and the new continuous book behavior still need dedicated verification.'], '4 — My Encyclopedias / manual user pages')
for n in [254,255]:
    review(n,'NOT VERIFIED',['Fruitfolio/Hormone Information/HormoneMeasurementHistoryChart.swift','FruitfolioTests/HormoneMeasurementHistoryTests.swift'],
           ['HormoneMeasurementHistoryTests/testOnlyActualPointsAreReturnedInDateOrderWithoutInterpolationOrMutation',
            'HormoneMeasurementHistoryTests/testDifferentExactUnitsHormonesAndSamplesAreNeverCombinedOrConverted'],
           ['Delivery/HORMONE_MEASUREMENT_DISPLAY_DECISION.md'],
           'New point-only history charts use actual records only, separate exact units and samples, retain original text and introduce no connected or fitted curves.',
           ['New chart source awaits actual Run46 compilation, unit execution, simulator visual/accessibility review.'], '4.9.6 / 4.9.8 — Actual measured values remain distinct')
for n in [281,282,283,287]:
    review(n,'PARTIAL',['Fruitfolio/Context Personalization/Prompt27APersonalHealthFields.swift','Fruitfolio/Context Personalization/Prompt27APersonalHealthView.swift','Fruitfolio/Context Personalization/Prompt27AContextModels.swift','Fruitfolio/Context Personalization/Prompt27AContextStore.swift'],
           ['PersonalHealthContextTests/testExistingContextMigratesWithoutInventingAnyMedicalFields','PersonalHealthContextTests/testReportedHistoryPersistsThroughTheExistingSharedStoreAndRemovalErasesItsText'],
           ['Delivery/PERSONAL_HEALTH_CONTEXT_IMPLEMENTATION.md'],
           'Existing shared context extended with illustrated optional reported-history fields, explicit provenance, migration, removal without retained text, and onboarding/reopen access.',
           ['Actual Run46 compilation/unit/UI tests pending. Relevance-limited approved-evidence retrieval and Ask personalization for these new fields remain unfinished; free text does not change prediction math.'],
           'Binding Personal Health Context and evidence-informed My Context additions')
for n in [419,427,430,439]:
    review(n,'PARTIAL',['Fruitfolio/Core/AppArchitecture/FruitfolioMADLADRuntime.swift','Fruitfolio/Core/AppArchitecture/FruitfolioMADLADDocumentTranslator.swift'],
           ['AAAA_MADLADRuntimeIntegrationTests/testOfficialModelExecutesLocallyThroughTheLinkedAppleRuntime'],[unit,'Delivery/MADLAD_MEDICAL_FIXTURE_REPAIR.md'],
           'Official local Q4 executes through the linked Apple encoder-decoder runtime; original runtime blocker is resolved for bounded sentences. New document-preservation fixture is pending Run46; no cloud/model substitute.',
           ['Production Ask remains gated pending semantic/language/device acceptance. New adapter, explicit execution-thread evidence and disabled-network device tests remain unverified.'],
           'MADLAD local encoder-decoder inference and verification')

assert len(records)==478 and len(data['requirements'])==478
data.update(totalRequirements=478,summary=dict(collections.Counter(r['implementationStatus'] for r in data['requirements'])),
            currentSourceCommit=current,latestVerifiedUnitCommit=commit,
            implementationPassVerificationNote='Actual Run45 source 8841840: 490 XCTest executed = 489 PASS + 1 physical-device SKIP, zero FAIL; 25 Swift Testing PASS. Simulator and unsigned generic iPhone Release builds PASS. Focused pages/Ask/volumes/username/Guide journeys PASS; SharedControls FAIL; remaining stages separate. Source 0435fa3 new changes are pending actual Run46.')
path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')
index={'scope':'Reference integrity only; file presence does not establish acceptance.', 'sourceCommit':current,'requirements':[],'missingActiveEvidence':[]}
for r in data['requirements']:
    evidence=[{'path':p,'exists':(root/p).is_file()} for p in r['supportingEvidence']]
    index['requirements'].append({'requirementID':r['requirementID'],'status':r['implementationStatus'],'evidence':evidence})
    index['missingActiveEvidence'] += [{'requirementID':r['requirementID'],'path':e['path']} for e in evidence if not e['exists']]
(root/'Fruitfolio_Verification_Evidence/requirement-to-evidence-index.json').write_text(json.dumps(index,indent=2)+'\n')
print(json.dumps({'summary':data['summary'],'missingActiveEvidence':len(index['missingActiveEvidence'])}))
