#!/usr/bin/env python3
"""Attach actual implementation-pass evidence without treating file existence as acceptance."""
from pathlib import Path
import json, collections
root=Path(__file__).resolve().parents[1]
p=root/'Delivery/ImplementationTracker478.json';d=json.loads(p.read_text())
by_id={r['requirementID']:r for r in d['requirements']}
def update(number, state, disposition, files, changes, tests, evidence, remaining):
 r=by_id[f'FF1B-{number:03}']
 r.setdefault('beforeStatus',r['implementationStatus'])
 r['currentImplementationState']=state;r['implementationAssessment']='ASSESSED'
 r['implementationStatus']=disposition;r['afterStatus']=disposition
 r['verificationState']={'PASS':'PASS','PARTIAL':'INCONCLUSIVE','FAIL':'FAIL','NOT VERIFIED':'NOT TESTED','BLOCKED':'NOT TESTED'}[disposition]
 r['inspectionState']={'IMPLEMENTED':'ALREADY IMPLEMENTED AND VERIFIED' if disposition=='PASS' else 'IMPLEMENTED BUT NOT VERIFIED','PARTIALLY IMPLEMENTED':'PARTIALLY IMPLEMENTED','BLOCKED':'BLOCKED BY TECHNICAL DEPENDENCY'}[state]
 r['relevantSourceFiles']=list(dict.fromkeys(r['relevantSourceFiles']+files));r['existingSourceFiles']=[f for f in r['relevantSourceFiles'] if (root/f).is_file()]
 r['changesMade']=list(dict.fromkeys(r['changesMade']+changes));r['testsPerformed']=list(dict.fromkeys(r['testsPerformed']+tests))
 r['testResults']=[{'result':r['verificationState'],'scope':('Complete item criterion' if disposition=='PASS' else 'Named implementation/test scope only; item remains incomplete'),'tests':tests}]
 r['supportingEvidence']=list(dict.fromkeys(r['supportingEvidence']+evidence));r['evidenceReferences']=r['supportingEvidence']
 r['remainingIssues']=remaining;r['missingImplementation']=remaining;r['finalDisposition']=disposition
 r['requiredAcceptanceTests']=[{'criterion':r['originalBreakdownItem'],'testIDs':tests,'assessment':'Linked actual tests; screen coverage limitations retained in remainingIssues'}]
 for h in [{'baseline':'implementation-first continuation','status':disposition}]:
  if h not in r['historicalStatuses']:r['historicalStatuses'].append(h)
unit='Fruitfolio_Verification_Evidence/AppleRuns/Run22/xcode-unit-test.log'
controls='Fruitfolio_Verification_Evidence/AppleRuns/Run22/SharedControls/Build/xcode-shared-controls-ui.log'
# Narrow component/data-flow criteria. Do not count global adoption requirements as complete.
update(28,'IMPLEMENTED','PASS',['Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift','Fruitfolio/Core/DesignSystems/FruitfolioProtectedDecoration.swift'],['Shared placement authority now consumes runtime text anchors and actual PNG painted bounds.'],['ProtectedDecorationTests/testActualAlphaFootprintProtectsTextWithoutBlanketHidingUnrelatedArtwork','SharedControlUITests/testContactArtworkControlsAndReturnNavigation','SharedControlUITests/testContactLongLabelGrowsAtAccessibilityTypeWithoutClipping'],[unit,controls],[])
update(46,'IMPLEMENTED','PASS',['Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift','Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift'],['One explicit-role interpretation supplies SwiftUI and selectable UIKit renderers; removed symptom keyword matching.'],['SemanticPipelineTests/testSameWordsReceiveOnlyTheirDeclaredContextualRole','UserAuthoredPageTests/testEditorCombinesAndTogglesTraitsWithoutRewritingUserText'],[unit],[])
update(61,'IMPLEMENTED','PASS',['Fruitfolio/Ask/Prompt09AskModels.swift','Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift','Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift'],['Semantic metadata passes through the actual Ask-save destination and shared library/guide copy; legacy decoding preserves unformatted evidence.'],['SemanticPipelineTests/testRepeatedExcerptUsesSelectedOccurrenceAndUnicodeBoundaries','SemanticPipelineTests/testSavedPageAndGuideReopenRetainFormattingSourceAndImages'],[unit],[])
for number in [1,2,3,4,6]:
 update(number,'PARTIALLY IMPLEMENTED','PARTIAL',['Fruitfolio/Core/DesignSystems/FruitfolioModalBlur.swift'],['Centralized blur, scale, dim, hit testing and accessibility hiding; removed duplicate feature-owned dim overlays from Ask, Settings, Account, Library and Guide Builder.'],[],[],['Full modal state, focus, dismissal and screen-by-screen acceptance is not yet established.'])
for number in range(7,13):
 update(number,'PARTIALLY IMPLEMENTED','PARTIAL',['Fruitfolio/Global Controls/Prompt08GlobalControls.swift','Fruitfolio/Hub/CutePopButtonStyle.swift','Fruitfolio/Hub/Prompt04HubBridgeView.swift'],['Primary and saved-library pills use original control artwork; labels wrap without font shrink; inherited canonical pop honors app and OS Reduce Motion. Hub no longer delays route actions.'],['SharedControlArtworkTests','SharedControlUITests'],[unit,controls],['All button destinations, audio synchronization and latency still need complete application-wide verification.'])
for number in range(13,28):
 update(number,'PARTIALLY IMPLEMENTED','PARTIAL',['Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift','Fruitfolio/Fruit Popup Engine/FruitPopupView.swift'],['Notebook and fruit dialogue share artwork-aspect and calibrated writing-region composition with bounded scrolling; Ask help uses the actual shared modal.'],['PopupLayoutTests/testNotebookWritingRegionAvoidsBindingAndRemainsInsideArtAtKeyboardAndPhoneSizes'],[unit],['Complete character, popup, audio, Dynamic Type and accessibility coverage remains incomplete; Ask help change awaits its own runtime evidence.'])
for number in [47,48,49,50,51,52,53,54,55,56,57,58,59,60,62,63,64]:
 update(number,'PARTIALLY IMPLEMENTED','PARTIAL',['Fruitfolio/Core/DesignSystems/FruitfolioSemanticAttributedRenderer.swift','Fruitfolio/Ask/Prompt09AskView.swift','Fruitfolio/Hub/FAQ/Prompt29FAQView.swift'],['Integrated role-based renderer into Ask, saved answers, Guide reading, manual editor and authored FAQ answers. Source text is never rewritten by mismatched formatting metadata.'],['SemanticPipelineTests','UserAuthoredPageTests'],[unit],['Contextual semantic authoring and adoption across every eligible generated surface is not complete. Later Ask progressive/FAQ integration still requires its own runtime verification.'])
for number in range(197,205):
 update(number,'PARTIALLY IMPLEMENTED','PARTIAL',['Fruitfolio/Saved Library/Prompt10UserPageEditor.swift','Fruitfolio/Saved Library/Prompt10ChapterManagementView.swift','Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift','Fruitfolio/Saved Library/Prompt10LocalMediaStore.swift'],['Chapter-owned user pages support explicit rich formatting, imported images, save/discard, editing and deletion. Shared-store chapter management moves the same page with its source metadata intact. Reader notes have an unsaved-edit guard.'],['UserAuthoredPageTests','ChapterManagementTests','SavedLibraryRecoveryTests','Prompt10LocalMediaStoreTests'],[unit],['Actual creation/relaunch/edit/discard/delete UI journey remains in repair; photo-picker import, cancellation and image-sharing flows need actual simulator/device verification. Physical file protection is NOT VERIFIED.'])
update(374,'BLOCKED','BLOCKED',['Fruitfolio/Hub/FAQ/Prompt29FAQView.swift'],['Inspected registered flower assets; no supplied asset was identifiable as the approved tulip. Removed unauthorized grass assignment without substituting other flowers.'],[],['Delivery/IMPLEMENTATION_PASS_RESOURCE_INTEGRITY.json'],['Missing identifiable approved tulip resource or authoritative mapping to an existing resource; unrelated implementation continues.'])
for r in d['requirements']:
 r.setdefault('afterStatus',r['implementationStatus'])
 r['finalDisposition']=r['implementationStatus']
d['implementationPassVerificationNote']='Run22: 460 XCTest passed, one explicitly skipped physical-device protection test (NOT VERIFIED), 25 Swift Testing passed. Unit success does not establish complete UI, medical, privacy or MADLAD acceptance.'
d['summary']=dict(collections.Counter(r['implementationStatus'] for r in d['requirements']))
d['totalRequirements']=len(d['requirements']);assert d['totalRequirements']==478
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n')
print(json.dumps(d['summary']))
