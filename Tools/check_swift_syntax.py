#!/usr/bin/env python3
"""Optional Linux syntax check. This does not typecheck, link or execute Swift."""
from pathlib import Path
import argparse
import subprocess
import shutil
from concurrent.futures import ThreadPoolExecutor
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--base', default='defa3c9')
    parser.add_argument('--swiftc', default=shutil.which('swiftc'), help='Use the real Swift compiler parse phase when available; does not typecheck or link')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    paths = set(subprocess.check_output(['git', 'diff', '--name-only', args.base], cwd=root, text=True).splitlines())
    paths.update(subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard'], cwd=root, text=True).splitlines())
    files = [(relative, root / relative) for relative in sorted(paths)
             if relative.endswith('.swift') and (root / relative).is_file()]
    failures = []
    if args.swiftc:
        def parse(item):
            relative, path = item
            result = subprocess.run([args.swiftc, '-frontend', '-parse', str(path)], cwd=root,
                                    text=True, capture_output=True)
            return relative, result
        with ThreadPoolExecutor(max_workers=4) as pool:
            for relative, result in pool.map(parse, files):
                if result.returncode:
                    failures.append(relative)
                    print(result.stderr or result.stdout, file=sys.stderr)
        provider = 'Swift compiler'
    else:
        try:
            from tree_sitter import Language, Parser
            import tree_sitter_swift
        except ImportError:
            parser.error('Provide --swiftc or install Tools/requirements-validation.txt')
        engine = Parser(Language(tree_sitter_swift.language()))
        for relative, path in files:
            if engine.parse(path.read_bytes()).root_node.has_error:
                failures.append(relative)
        provider = 'optional Tree-sitter parser'
    for path in failures:
        print('Swift syntax parse failed: ' + path, file=sys.stderr)
    print(f'{len(files)} Swift files parsed with {provider}, {len(failures)} with syntax errors. Typechecking/link/runtime NOT verified.')
    return bool(failures)

if __name__ == '__main__':
    raise SystemExit(main())
