#!/usr/bin/env python3
"""Check real XCFramework metadata for the requested test/release platforms."""
import argparse
from pathlib import Path
import plistlib


def inspect(root, required=None, simulator_architecture=None):
    required = {'device', 'simulator'} if required is None else set(required)
    if not required or not required <= {'device', 'simulator'}:
        raise ValueError('Requested coverage must contain device and/or simulator')
    if simulator_architecture not in {None, 'arm64', 'x86_64'}:
        raise ValueError('Unsupported simulator architecture')
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
        if variant == 'simulator':
            matching = {simulator_architecture} if simulator_architecture else {'arm64', 'x86_64'}
            if architectures & matching:
                covered.add('simulator')
        elif not variant and 'arm64' in architectures:
            covered.add('device')
    if not required <= covered:
        if required == {'device', 'simulator'} and simulator_architecture is None:
            raise ValueError('Both iOS arm64 device and iOS simulator libraries are required; simulator-only frameworks cannot run on an iPhone.')
        missing = ', '.join(sorted(required - covered))
        raise ValueError(f'Missing requested iOS coverage: {missing}; simulator architecture: {simulator_architecture or "any supported"}. Build the matching native runtime before testing.')
    return covered


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path', type=Path, nargs='?', default=Path(__file__).resolve().parents[1] / 'Fruitfolio/Frameworks/llama.xcframework')
    parser.add_argument('--target', choices=['release', 'device', 'simulator'], default='release')
    parser.add_argument('--simulator-architecture', choices=['arm64', 'x86_64'])
    args = parser.parse_args()
    required = {'device', 'simulator'} if args.target == 'release' else {args.target}
    try:
        inspect(args.path, required=required, simulator_architecture=args.simulator_architecture)
    except (ValueError, OSError, plistlib.InvalidFileException) as error:
        parser.exit(2, str(error) + '\n')
    print(f'XCFramework metadata covers requested {args.target} target. Actual binary compatibility, linking and inference still require Xcode tests.')

if __name__ == '__main__':
    main()
