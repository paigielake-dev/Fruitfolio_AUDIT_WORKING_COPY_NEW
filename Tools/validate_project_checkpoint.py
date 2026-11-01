#!/usr/bin/env python3
"""Static checkpoint checks. Does not compile Swift or verify app behavior."""
import json
from pathlib import Path
import subprocess
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
results = []

def check(name, passed, details):
    results.append({'name': name, 'result': 'PASS' if passed else 'FAIL', 'scope': 'static only', 'details': details})

missing = []
references = 0
for path in (root / 'Fruitfolio/Assets.xcassets').rglob('Contents.json'):
    payload = json.loads(path.read_text())
    for kind in ('images', 'data'):
        for item in payload.get(kind, []):
            if 'filename' in item:
                references += 1
                if not (path.parent / item['filename']).is_file(): missing.append(str(path.parent / item['filename']))
check('Asset catalog payloads exist', not missing, {'references': references, 'missing': missing})
model = root / 'FruitfolioAI.gguf'
with model.open('rb') as stream: magic = stream.read(4)
check('Fruitfolio model is real GGUF, not LFS pointer', magic == b'GGUF', {'bytes': model.stat().st_size})
project = (root / 'Fruitfolio.xcodeproj/project.pbxproj').read_text()
check('Desktop-only framework path removed', '/Users/' not in project, 'Does not prove Apple linking succeeds.')
ET.parse(root / 'Fruitfolio.xcodeproj/xcshareddata/xcschemes/Fruitfolio.xcscheme')
check('Shared Xcode scheme XML parses', True, 'Xcode has not loaded this scheme.')
package = root / 'Fruitfolio/FruitfolioResearchPackage.json'
check('Required research package available', package.is_file(), 'The bundled PDF/DOCX are not a replacement for the runtime index.')
check('iOS XCFramework available', (root / 'Vendor/llama.xcframework/Info.plist').exists(), 'Run the staged Apple build recipe and verify import/link on a Mac.')
parsed = []
try:
    import tree_sitter, tree_sitter_swift
    parser = tree_sitter.Parser(tree_sitter.Language(tree_sitter_swift.language()))
    changed = subprocess.check_output(['git','diff','defa3c9c062230325262e6f36296d0877655ad5e','--name-only'],cwd=root,text=True).splitlines()
    candidates = [root / p for p in changed if p.endswith('.swift')]
    candidates += list((root / 'Fruitfolio/Hormone Information').glob('*.swift'))
    candidates += [root / 'FruitfolioTests/AskSessionLifetimeTests.swift', root / 'FruitfolioTests/HormoneMeasurementTests.swift', root / 'FruitfolioTests/ResearchPackageBundleTests.swift']
    for path in sorted(set(candidates)):
        tree = parser.parse(path.read_bytes())
        errors = []
        def walk(node):
            if node.type == 'ERROR' or node.is_missing:
                errors.append({'type': node.type, 'line': node.start_point.row + 1})
            for child in node.children: walk(child)
        walk(tree.root_node)
        parsed.append({'file': str(path.relative_to(root)), 'errors': errors})
    check('Changed Swift files parse', all(not p['errors'] for p in parsed), parsed)
except ImportError:
    results.append({'name':'Changed Swift files parse','result':'NOT RUN','details':'Install tree-sitter and tree-sitter-swift.'})
output = root / 'Fruitfolio_Verification_Evidence/Build/static-checks.json'
output.write_text(json.dumps(results, indent=2))
for result in results: print(result['result'] + ': ' + result['name'])
# Missing production resources deliberately fail this checkpoint gate.
raise SystemExit(1 if any(r['result'] == 'FAIL' for r in results) else 0)
