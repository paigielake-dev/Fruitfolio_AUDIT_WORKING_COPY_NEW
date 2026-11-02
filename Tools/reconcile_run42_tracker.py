#!/usr/bin/env python3
"""Reconcile only the explicitly reviewed criteria against real Apple evidence."""
from pathlib import Path
import json, collections
root=Path(__file__).resolve().parents[1]
p=root/'Delivery/ImplementationTracker478.json'; data=json.loads(p.read_text())
records={r['requirementID']:r for r in data['requirements']}
unit='Fruitfolio_Verification_Evidence/AppleRuns/Run42/UnitBuild/xcode-unit-test.log'
vol='Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/Build/xcode-volume-ui-test.log'
# Artifact uses the original runner filename; never manufacture an absent log.
if not (root/vol).is_file():
    matches=list((root/'Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/Build').glob('*volume*.log'))
    assert len(matches)==1
    vol=str(matches[0].relative_to(root))
horm='Fruitfolio_Verification_Evidence/AppleRuns/Run41/Build/xcode-hormone-ui-test.log'

def record(n,status,state,files,changes,tests,evidence,remaining,section):
    r=records[f'FF1B-{n:03}']
    for e in evidence: assert (root/e).exists(),e
    r['historicalStatuses'].append({'baseline':'Run42 review of exact tested source 6b6a24d; UI Run41 exact source 2d06a17','status':r['implementationStatus']})
    r.update(currentImplementationState=state,implementationAssessment='ASSESSED',implementationStatus=status,afterStatus=status,finalDisposition=status,
             verificationState='PASS' if status=='PASS' else 'INCONCLUSIVE',inspectionState='ALREADY IMPLEMENTED AND VERIFIED' if status=='PASS' else 'PARTIALLY IMPLEMENTED',remainingIssues=remaining,missingImplementation=remaining)
    r['prompt1BSection']={'candidateSection':section,'exactCrossReferenceStatus':'Reviewed corresponding authoritative Prompt1B text; retained original numbered breakdown reference'}
    r['sourceSection']=r['prompt1BSection']
    for key,values in [('relevantSourceFiles',files),('changesMade',changes),('testsPerformed',tests),('supportingEvidence',evidence)]:
        r[key]=list(dict.fromkeys(r.get(key,[])+values))
    r['existingSourceFiles']=[f for f in r['relevantSourceFiles'] if (root/f).is_file()]
    r['evidenceReferences']=r['supportingEvidence']
    r['testResults']=[{'result':'PASS' if status=='PASS' else 'PARTIAL','scope':'Exact criterion only; no broader feature acceptance inferred','tests':tests,'verifiedSourceCommits':['6b6a24d0faaf6d39ddd2ea52605040b3a199a30a','2d06a17810125d9c33a719bc60663256372432f7']}]
    r['requiredAcceptanceTests']=[{'criterion':r['originalBreakdownItem'],'testIDs':tests,'assessment':'Actual named runtime tests and separate evidence review; pending work explicitly retained'}]

record(222,'PASS','IMPLEMENTED',['Fruitfolio/Privacy Settings/Prompt12SettingsView.swift','Fruitfolio/Global Controls/FruitfolioArtworkVolumeSlider.swift'],
       ['Preserved original painted artwork in four independently adjustable native UISliders; continuous original track underlay avoids split-track seams.'],
       ['SettingsVolumeUITests/testOriginalArtworkControlsChangeIndependentlyAndPersistAfterRestart'],[vol,'Fruitfolio_Verification_Evidence/AppleRuns/Run41/SettingsVolumes/visual-review.md'],[], '6B — Individual audio preference changes')
record(223,'PASS','IMPLEMENTED',['Fruitfolio/Core/Assets/AudioManager.swift'],['Apply newly published volume values to the corresponding actual category players.'],
       ['AudioLifecycleRuntimeTests/testActualMusicAndRainPlayersRemainIndependentAndSettingsMuteOnlyTheirCategory','AudioLifecycleRuntimeTests/testMasterMuteStopsActualPlayersAndOnlyResumesEnabledRequestedLoops'],[unit],[],'6B — Individual audio preference changes')
for n in [224,225]:
    record(n,'PARTIAL','PARTIALLY IMPLEMENTED',['Fruitfolio/Core/Assets/AudioManager.swift','Fruitfolio/Core/AppArchitecture/SettingsStore.swift','Fruitfolio/Privacy Settings/Prompt12SettingsView.swift'],
           ['Persistent master mute and existing category controls affect actual playback; no changes to other category preferences.'],
           ['AudioLifecycleRuntimeTests/testMasterMuteStopsActualPlayersAndOnlyResumesEnabledRequestedLoops','AudioLifecycleRuntimeTests/testPersistedMasterMutePreventsPlaybackAfterStoreAndManagerRestart'],[unit],['Actual master-control simulator interaction and current visible layout are still running in Run42; audible quality remains separately NOT VERIFIED.'],'6A/6B — Settings and actual audio preferences')
record(226,'PASS','IMPLEMENTED',['Fruitfolio/Core/Assets/AudioManager.swift'],['Disabled continuous players actually pause; master mute pauses music/rain and stops/removes effects/typing players, blocks new requests, and does not replay old cues.'],
       ['AudioLifecycleRuntimeTests/testActualMusicAndRainPlayersRemainIndependentAndSettingsMuteOnlyTheirCategory','AudioLifecycleRuntimeTests/testMasterMuteStopsActualPlayersAndOnlyResumesEnabledRequestedLoops','AudioLifecycleRuntimeTests/testPersistedMasterMutePreventsPlaybackAfterStoreAndManagerRestart'],[unit,'Fruitfolio_Verification_Evidence/AppleRuns/Run42/actual-runtime-attachments-index.json'],[],'6B — Actual category and master audio behavior')
record(227,'PASS','IMPLEMENTED',['Fruitfolio/Core/AppArchitecture/SettingsStore.swift'],['Category preferences, all four volumes and master mute persist independently; actual manager restart obeys persisted mute.'],
       ['Prompt03ArchitectureTests/testSettingsPersistAcrossInstances','Prompt03ArchitectureTests/testVolumePersistenceClampsToValidRange','AudioLifecycleRuntimeTests/testPersistedMasterMutePreventsPlaybackAfterStoreAndManagerRestart','SettingsVolumeUITests/testOriginalArtworkControlsChangeIndependentlyAndPersistAfterRestart'],[unit,vol],[],'6B — Persist selected independent volume and audio preferences')
record(253,'PASS','IMPLEMENTED',['Fruitfolio/Hormone Information/HormoneMeasurementStore.swift','Fruitfolio/Hormone Information/HormoneMeasurement.swift'],['Actual protected local store retains multiple dated results without replacing another measurement, converting original units, or filling absent optional values.'],
       ['HormoneMeasurementTests/testRepeatedResultsRetainTheirOwnDatesOptionalFieldsAndExactStrings','Prompt22MeasurementPresentationTests/testReferencePresentationDoesNotInventValuesOrRewriteStoredMeasurements'],[unit],[],'4.9.6 — Measurement history: repeated measurements over time')
record(458,'PASS','IMPLEMENTED',['Fruitfolio/Hormone Information/HormoneInformationView.swift','FruitfolioUITests/HormoneMeasurementUITests.swift'],['Fixed scroll-owner selection; actual UI creates, saves, restarts, reopens, edits, saves, and confirms deletion of its own uniquely identified record.'],
       ['HormoneMeasurementUITests/testCreateRestartEditAndDeleteMeasurement'],[horm,'Fruitfolio_Verification_Evidence/AppleRuns/Run41/Visual/HormoneInformation/manifest.json'],[],'4.9.1/4.9.5/4.9.6 — Actual hormone record lifecycle')
for n in [230,231,463]:
    record(n,'PARTIAL','PARTIALLY IMPLEMENTED',['Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift','Fruitfolio/Privacy Settings/Prompt12AccountView.swift','Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift','FruitfolioUITests/UsernameSynchronizationUITests.swift'],
           ['One persistent authority already shared by both features; fixed Fruit Basket editor rejecting first/second keystrokes by separating incomplete draft from validated public name.'],
           ['FruitfolioUsernameStoreTests/testUsernamePersistsThroughSingleAuthority'],[unit,'Delivery/USERNAME_EDITING_REPAIR.md'],['New actual cross-feature ordinary-typing/restart journey has not yet executed. Global authenticated username reservation remains unavailable.'],'6F and 19X — Shared Account/Fruit Basket username')
assert "testCreateRestartEditAndDeleteMeasurement]' passed" in (root/horm).read_text()
assert len(data['requirements'])==478
# Ensure names written into the tracker correspond to actual XCTest cases.
actual=json.loads((root/'Delivery/LatestAppleTestResults.json').read_text())
known={r['testID'] for r in actual['XCTestResults']}
for n in [223,224,225,226,227,253,230,231,463]:
    for t in records[f'FF1B-{n:03}']['testsPerformed']:
        if t.startswith(('AudioLifecycleRuntimeTests/','Prompt03ArchitectureTests/','HormoneMeasurementTests/','Prompt22MeasurementPresentationTests/','FruitfolioUsernameStoreTests/')):
            assert t in known, t
summary=dict(collections.Counter(r['implementationStatus'] for r in data['requirements']))
data.update(summary=summary,totalRequirements=478,implementationPassVerificationNote='Run42 exact source 6b6a24d: 481 XCTest executed, 480 PASS, one physical-device SKIP, zero FAIL; 25 Swift Testing PASS. Unsigned generic iPhone Release build PASS. Focused simulator results remain separate; no pending result is PASS. Later working-tree repairs are NOT VERIFIED.')
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n');print(json.dumps(summary))
