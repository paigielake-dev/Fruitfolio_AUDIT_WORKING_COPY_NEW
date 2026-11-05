#!/usr/bin/env python3
"""Check real XCFramework metadata for both device and simulator coverage."""
import argparse
from pathlib import Path
import plistlib


def inspect(root):
    root = Path(root).resolve()
    metadata = root / 'Info.plist'
    if not metadata.is_file():
        raise ValueError('Missing llama.xcframework. Run bash Tools/build_llama_xcframework_mac.sh on a Mac.')
    data = plistlib.loads(metadata.read_bytes())
    covered = set()
    for library in data.get('AvailableLibraries', []):
        if library.get('SupportedPlatform') != 'ios':
            continue
        identifier = library.get('LibraryIdentifier', '')
        library_path = library.get('LibraryPath', '')
        artifact = (root / identifier / library_path).resolve()
        if not artifact.is_relative_to(root) or not artifact.exists():
            raise ValueError('XCFramework declares a missing or escaping library artifact')
        architectures = set(library.get('SupportedArchitectures', []))
        variant = library.get('SupportedPlatformVariant', '')
        if variant == 'simulator' and architectures & {'arm64', 'x86_64'}:
            covered.add('simulator')
        elif not variant and 'arm64' in architectures:
            covered.add('device')
    if covered != {'device', 'simulator'}:
        raise ValueError('Both iOS arm64 device and iOS simulator libraries are required; simulator-only frameworks cannot run on an iPhone.')
    return covered


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', type=Path, nargs='?', default=Path(__file__).resolve().parents[1] / 'Fruitfolio/Frameworks/llama.xcframework')
    args = parser.parse_args()
    try:
        inspect(args.path)
    except (ValueError, OSError, plistlib.InvalidFileException) as error:
        parser.exit(2, str(error) + '\n')
    print('XCFramework declares both iOS device and simulator slices. Linking/inference still require Xcode tests.')

if __name__ == '__main__':
    main()
