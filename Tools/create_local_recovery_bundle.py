#!/usr/bin/env python3
"""Create a verified local Git recovery bundle. No network, push or merge."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
from datetime import datetime, timezone


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args], text=True).strip()


def create(repo, output, branch='development/prompt-1b-complete', base_ref='refs/remotes/origin/main'):
    repo = Path(git(repo, 'rev-parse', '--show-toplevel')).resolve()
    if git(repo, 'status', '--porcelain'):
        raise ValueError('Commit or preserve all pending changes first; this bundle must describe a clean checkpoint.')
    current = git(repo, 'symbolic-ref', '--short', 'HEAD')
    if current != branch:
        raise ValueError(f'Expected {branch}, found {current}; no refs were changed.')
    head = git(repo, 'rev-parse', 'HEAD')
    base = git(repo, 'merge-base', 'HEAD', base_ref)
    if base == head:
        raise ValueError('No checkpoint commits exist beyond the verified prerequisite.')
    output = Path(output).resolve()
    if output.is_relative_to(repo):
        raise ValueError('Place the recovery bundle outside the checkout so it cannot stage itself.')
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + '.tmp')
    try:
        subprocess.run(['git', '-C', str(repo), 'bundle', 'create', str(temporary), branch, '^' + base],
                       check=True, capture_output=True, text=True)
        verified = subprocess.run(['git', '-C', str(repo), 'bundle', 'verify', str(temporary)],
                                  check=True, capture_output=True, text=True)
        refs = git(repo, 'bundle', 'list-heads', str(temporary)).splitlines()
        if f'{head} refs/heads/{branch}' not in refs:
            raise ValueError('Recovery bundle does not contain the expected branch tip.')
        temporary.replace(output)
    finally:
        temporary.unlink(missing_ok=True)
    digest = hashlib.sha256()
    with output.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''): digest.update(block)
    manifest = {
        'created_at': datetime.now(timezone.utc).isoformat(), 'branch': branch, 'HEAD': head,
        'prerequisite_commit': base, 'base_ref': base_ref,
        'checkpoint_commits': int(git(repo, 'rev-list', '--count', base + '..' + head)),
        'bundle': str(output), 'sha256': digest.hexdigest(), 'bytes': output.stat().st_size,
        'verification': 'git bundle verify and expected tip verified locally',
        'limits': 'Git objects only; prerequisite must exist. LFS artwork/model assets require normal repository/LFS recovery. Local bundle is not remote backup or proof of cloud persistence.',
        'restore': ['Clone the existing repository and restore required LFS assets.',
                    f'git fetch <bundle-path> refs/heads/{branch}:refs/heads/{branch}',
                    f'git switch {branch}', 'Read development_workflow/CURRENT_CHECKPOINT.json; actual git log is authoritative.'],
    }
    output.with_suffix(output.suffix + '.json').write_text(json.dumps(manifest, indent=2) + '\n')
    return manifest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    manifest = create(args.repo, args.output)
    print(json.dumps({key: manifest[key] for key in ['HEAD', 'bundle', 'sha256', 'bytes', 'checkpoint_commits']}))


if __name__ == '__main__': main()
