#!/usr/bin/env python3
"""Report declared UI catalog coverage; never infer translation/runtime acceptance."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re


def units(value):
    if not isinstance(value, dict):
        return []
    result = []
    if isinstance(value.get('stringUnit'), dict):
        unit = value['stringUnit']
        if isinstance(unit.get('value'), str) and unit['value'].strip():
            result.append(unit)
    for key, nested in value.items():
        if key != 'stringUnit' and isinstance(nested, dict):
            result.extend(units(nested))
    return result


def summarize(catalog, languages):
    strings = catalog['strings']
    source = catalog.get('sourceLanguage', 'en')
    rows = []
    for language in languages:
        entries = 0
        different = 0
        states = Counter()
        for key, record in strings.items():
            localizations = record.get('localizations', {})
            values = units(localizations.get(language, {}))
            if not values:
                continue
            entries += 1
            states.update(unit.get('state', 'unspecified') for unit in values)
            original = [unit['value'] for unit in units(localizations.get(source, {}))] or [key]
            if [unit['value'] for unit in values] != original:
                different += 1
        rows.append({'language': language, 'declaredNonemptyEntries': entries,
                     'entriesDifferentFromSource': different,
                     'missingExplicitEntries': len(strings) - entries,
                     'declaredUnitStates': dict(states),
                     'acceptanceStatus': 'NOT VERIFIED',
                     'note': 'Catalog metadata only; not compilation, native review, screen coverage or scientific translation approval.'})
    return {'sourceLanguage': source, 'keyCount': len(strings), 'languageCount': len(languages),
            'languages': rows, 'MADLADInference': 'EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    root = args.root
    catalog_path = root / 'Fruitfolio/Localizable.xcstrings'
    data = catalog_path.read_bytes()
    declaration = …2110 tokens truncated…solutionTests.swift",
        "FruitfolioTests/NativeLocalizationSpeechTests.swift"
      ],
      "remainingIssues": "Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance."
    },
    {
      "requirementID": "FF1B-401",
      "originalBreakdownItem": "Support the specified major Asian languages.",
      "status": "PARTIAL",
      "implementationFiles": [
        "Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift",
        "Fruitfolio/Global Controls/Prompt08GlobalControls.swift",
        "Fruitfolio/Privacy Settings/Prompt12SettingsView.swift"
      ],
      "changes": "Locale resolution retains exact script identity; explicit Traditional/Simplified Chinese choices cannot fall through to an ambiguous generic Chinese bundle. Valid translations identical to their keys are recognized using a missing-resource sentinel. Source-language fallback can resolve authored English resource values while preserving explicit caller wording. Resolution exposes actual resource language for native speech hints. User-authored/unkeyed text remains unlocalized. Settings explicitly disclose incomplete interface coverage separately from research/answer readiness.",
      "verification": "Five Bundle-resource resolution tests and three real hosted UILabel tests were added, including script isolation, fallback, key-equal translations, speech metadata and unkeyed user text. Not executed on Mac. No inference or translation model was run.",
      "evidence": [
        "FruitfolioTests/UILocalizationResolutionTests.swift",
        "FruitfolioTests/NativeLocalizationSpeechTests.swift"
      ],
      "remainingIssues": "Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance."
    },
    {
      "requirementID": "FF1B-408",
      "originalBreakdownItem": "Build an extensible language architecture.",
      "status": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "implementationFiles": [
        "Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift",
        "Fruitfolio/Global Controls/Prompt08GlobalControls.swift",
        "Fruitfolio/Privacy Settings/Prompt12SettingsView.swift"
      ],
      "changes": "Locale resolution retains exact script identity; explicit Traditional/Simplified Chinese choices cannot fall through to an ambiguous generic Chinese bundle. Valid translations identical to their keys are recognized using a missing-resource sentinel. Source-language fallback can resolve authored English resource values while preserving explicit caller wording. Resolution exposes actual resource language for native speech hints. User-authored/unkeyed text remains unlocalized. Settings explicitly disclose incomplete interface coverage separately from research/answer readiness.",
      "verification": "Five Bundle-resource resolution tests and three real hosted UILabel tests were added, including script isolation, fallback, key-equal translations, speech metadata and unkeyed user text. Not executed on Mac. No inference or translation model was run.",
      "evidence": [
        "FruitfolioTests/UILocalizationResolutionTests.swift",
        "FruitfolioTests/NativeLocalizationSpeechTests.swift"
      ],
      "remainingIssues": "Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance."
    },
    {
      "requirementID": "FF1B-434",
      "originalBreakdownItem": "Do not silently overwrite user-authored content with translations.",
      "status": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "implementationFiles": [
        "Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift",
        "Fruitfolio/Global Controls/Prompt08GlobalControls.swift",
        "Fruitfolio/Privacy Settings/Prompt12SettingsView.swift"
      ],
      "changes": "Locale resolution retains exact script identity; explicit Traditional/Simplified Chinese choices cannot fall through to an ambiguous generic Chinese bundle. Valid translations identical to their keys are recognized using a missing-resource sentinel. Source-language fallback can resolve authored English resource values while preserving explicit caller wording. Resolution exposes actual resource language for native speech hints. User-authored/unkeyed text remains unlocalized. Settings explicitly disclose incomplete interface coverage separately from research/answer readiness.",
      "verification": "Five Bundle-resource resolution tests and three real hosted UILabel tests were added, including script isolation, fallback, key-equal translations, speech metadata and unkeyed user text. Not executed on Mac. No inference or translation model was run.",
      "evidence": [
        "FruitfolioTests/UILocalizationResolutionTests.swift",
        "FruitfolioTests/NativeLocalizationSpeechTests.swift"
      ],
      "remainingIssues": "Catalog coverage and native-language review remain incomplete. Run existing persistence/RTL/Chinese selector journeys and these native tests on founder Mac; do not infer full multilingual clinical acceptance."
    },
    {
      "requirementID": "FF1B-398",
      "originalBreakdownItem": "Persist the language preference across restarts and navigation.",
      "status": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "implementationFiles": [
        "Fruitfolio/Core/AppArchitecture/SettingsStore.swift",
        "Fruitfolio/Privacy Settings/Prompt12SettingsView.swift"
      ],
      "changes": "Unknown or unreadable saved language preferences are preserved and explicitly disclosed while English is used as a temporary fallback. Only an intentional new selection replaces the original value and clears the notice. Existing underscore Chinese-script spelling is recognized without changing its stored bytes or substituting the other script. Shared language decoding is used by Settings and non-SwiftUI preference reads.",
      "verification": "Four XCTest cases added: unknown value across restarts/replacement, wrong stored type preservation, Traditional underscore-script retention, and all60 existing identities loading without warning. Not executed on Mac.",
      "evidence": "FruitfolioTests/LanguagePreferenceRecoveryTests.swift",
      "remainingIssues": "Run actual Settings recovery notices, language restart/RTL journeys and existing preferences/audio regression on founder Mac."
    },
    {
      "requirementID": "FF1B-429",
      "originalBreakdownItem": "Do not silently reset the selected language.",
      "status": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "implementationFiles": [
        "Fruitfolio/Core/AppArchitecture/SettingsStore.swift",
        "Fruitfolio/Privacy Settings/Prompt12SettingsView.swift"
      ],
      "changes": "Unknown or unreadable saved language preferences are preserved and explicitly disclosed while English is used as a temporary fallback. Only an intentional new selection replaces the original value and clears the notice. Existing underscore Chinese-script spelling is recognized without changing its stored bytes or substituting the other script. Shared language decoding is used by Settings and non-SwiftUI preference reads.",
      "verification": "Four XCTest cases added: unknown value across restarts/replacement, wrong stored type preservation, Traditional underscore-script retention, and all60 existing identities loading without warning. Not executed on Mac.",
      "evidence": "FruitfolioTests/LanguagePreferenceRecoveryTests.swift",
      "remainingIssues": "Run actual Settings recovery notices, language restart/RTL journeys and existing preferences/audio regression on founder Mac."
    }
  ]
}
