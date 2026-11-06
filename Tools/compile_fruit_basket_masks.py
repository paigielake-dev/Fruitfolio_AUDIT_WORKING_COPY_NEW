#!/usr/bin/env python3
"""Derive collision data by reading original alpha; never write image files.

Pillow is a build/verification dependency only. The iOS app reads the bundled JSON.
"""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import sys
from PIL import Image

GRID = 96
THRESHOLD = 32
NAMES = ('vines', 'branch', 'puddle')


def compile_masks(root: Path) -> dict:
    masks = []
    for name in NAMES:
        relative = f'Fruitfolio/Assets.xcassets/Art/FruitBasket/fruitbasket_{name}.imageset/fruitbasket_{name}.png'
        path = root / relative
        source = path.read_bytes()
        with Image.open(path) as image:
            alpha = image.getchannel('A')
            width, height = image.size
            bounds = alpha.point(lambda value: 255 if value >= THRESHOLD else 0).getbbox()
            if not bounds:
                raise ValueError(f'No visible source paint: {relative}')
            packed = bytearray((GRID * GRID + 7) // 8)
            for row in range(GRID):
                for column in range(GRID):
                    tile = alpha.crop((column * width // GRID, row * height // GRID,
                                       (column + 1) * width // GRID, (row + 1) * height // GRID))
                    if tile.getextrema()[1] >= THRESHOLD:
                        index = row * GRID + column
                        packed[index // 8] |= 1 << (index % 8)
            masks.append({'name': name, 'sourcePath': relative, 'sha256': hashlib.sha256(source).hexdigest(),
                          'sourceWidth': width, 'sourceHeight': height, 'columns': GRID, 'rows': GRID,
                          'alphaBounds': [bounds[0] / width, bounds[1] / height,
                                          (bounds[2] - bounds[0]) / width, (bounds[3] - bounds[1]) / height],
                          'bits': base64.b64encode(packed).decode('ascii')})
        if path.read_bytes() != source:
            raise RuntimeError(f'Source art changed during compilation: {relative}')
    return {'version': 1, 'alphaThreshold': THRESHOLD, 'masks': masks}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--output', type=Path)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    output = args.output or args.repo / 'Fruitfolio/Fruit Basket/Prompt28ObstacleMasks.json'
    expected = json.dumps(compile_masks(args.repo), indent=2, ensure_ascii=False) + '\n'
    if args.check:
        if not output.exists() or output.read_text() != expected:
            print('Fruit Basket collision masks differ from the preserved source PNGs; regenerate before review.', file=sys.stderr)
            return 1
        print('3 Fruit Basket collision masks match original source alpha and SHA256; image bytes unchanged.')
    else:
        output.write_text(expected)
        print(f'Wrote collision data for 3 preserved PNGs: {output}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
