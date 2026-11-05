#!/usr/bin/env python3
"""Optional Linux syntax check. This does not typecheck, link or execute Swift."""
from pathlib import Path
import argparse
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', default='defa3c9')
    args = parser.parse_args()
    try:
        from tree_sitter import Language, Parser
        import tree_sitter_swift
    except ImportError:
        parser.error('Install Tools/requirements-validation.txt before running this check')
    root = Path(__file__).resolve().parents[1]
    engine = Parser(Language(tree_sitter_swift.language()))
    paths = set(subprocess.check_output(['git', 'diff', '--name-only', args.base], cwd=root, text=True).splitlines())
    paths.update(subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard'], cwd=root, text=True).splitlines())
    checked = 0
    failures = []
    for relative in sorted(paths):
        path = root / relative
        if not relative.endswith('.swift') or not path.is_file():
            continue
        checked += 1
        if engine.parse(path.read_bytes()).root_node.has_error:
            failures.append(relative)
    for path in failures:
        print('Swift syntax parse failed: ' + path, file=sys.stderr)
    print(f'{checked} Swift files parsed, {len(failures)} with syntax errors. Compilation/runtime NOT verified.')
    return bool(failures)

if __name__ == '__main__':
    raise SystemExit(main())
