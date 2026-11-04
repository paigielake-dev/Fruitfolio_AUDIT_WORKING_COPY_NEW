#!/usr/bin/env python3
"""Verify ordered Fruitfolio binary parts and reconstruct their exact ZIP offline."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import tempfile


def digest(path):
    # Also works with the Python3.9 supplied by some Mac developer tools.
    result = hashlib.sha256()
    with path.open('rb') as source:
        while block := source.read(8 * 1024 * 1024): result.update(block)
    return result.hexdigest()


def reconstruct(index_path):
    index_path = index_path.resolve()
    directory = index_path.parent
    index = json.loads(index_path.read_text())
    archive_name = index['archive']
    if Path(archive_name).name != archive_name or not archive_name.endswith('.zip'):
        raise ValueError('Unsafe archive name in parts index')
    output = directory / archive_name
    if output.exists():
        if output.is_file() and digest(output) == index['sha256']:
            print('The existing archive already matches the exact verified SHA256: ' + str(output))
            return output
        raise FileExistsError('An existing different output will not be overwritten: ' + str(output))
    parts = index['parts']
    if not parts: raise ValueError('No archive parts are listed')
    total = 0
    for position, part in enumerate(parts, 1):
        name = part['name']
        if name != archive_name + '.part' + f'{position:02d}' or Path(name).name != name:
            raise ValueError('Part order or filename differs from the exact archive sequence')
        path = directory / name
        if not path.is_file(): raise FileNotFoundError('Download this missing part: ' + name)
        if path.stat().st_size != part['bytes'] or digest(path) != part['sha256']:
            raise ValueError('Size/SHA256 verification failed; replace this part: ' + name)
        total += part['bytes']
        print('Verified ' + name, flush=True)
    if total != index['bytes']: raise ValueError('Part sizes do not equal the complete archive size')
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=directory, prefix='.Fruitfolio-reconstruction-', delete=False) as target:
            temporary = Path(target.name)
            for part in parts:
                with (directory / part['name']).open('rb') as source:
                    while block := source.read(8 * 1024 * 1024): target.write(block)
            target.flush(); os.fsync(target.fileno())
        if digest(temporary) != index['sha256']:
            raise ValueError('Reconstructed full-archive SHA256 does not match')
        # Same-directory hard link publishes the verified file without replacing
        # any output that another process may have created after our first check.
        os.link(temporary, output)
        temporary.unlink(); temporary = None
        print('Verified complete archive: ' + str(output))
        print('SHA256: ' + index['sha256'])
        print('Extract the ZIP preserving filenames, then open Fruitfolio.xcodeproj.')
        return output
    finally:
        if temporary is not None: temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('parts_index', type=Path, help='Downloaded ZIP.parts.json beside every numbered binary part')
    args = parser.parse_args()
    reconstruct(args.parts_index)


if __name__ == '__main__':
    main()
