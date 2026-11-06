import hashlib
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('fruit_basket_masks', ROOT / 'Tools/compile_fruit_basket_masks.py')
MASKS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MASKS)


class FruitBasketMaskTests(unittest.TestCase):
    def test_actual_bundle_matches_original_source_alpha(self):
        expected = MASKS.compile_masks(ROOT)
        actual = json.loads((ROOT / 'Fruitfolio/Fruit Basket/Prompt28ObstacleMasks.json').read_text())
        self.assertEqual(actual, expected)

    def test_compilation_is_reproducible_and_does_not_change_artwork(self):
        paths = [ROOT / f'Fruitfolio/Assets.xcassets/Art/FruitBasket/fruitbasket_{name}.imageset/fruitbasket_{name}.png' for name in MASKS.NAMES]
        before = {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}
        self.assertEqual(MASKS.compile_masks(ROOT), MASKS.compile_masks(ROOT))
        self.assertEqual(before, {path: hashlib.sha256(path.read_bytes()).hexdigest() for path in paths})
