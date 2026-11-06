"""Compare actual compiled production palette metadata with untouched PNGs."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

try:
    from PIL import Image
except ImportError:
    Image = None

ROOT = Path(__file__).resolve().parents[2]
SWIFTC = os.environ.get("FRUITFOLIO_SWIFTC") or shutil.which("swiftc")


@unittest.skipUnless(SWIFTC and Image, "Swift compiler and Pillow art-analysis dependencies required")
class HeaderArtworkMetricsTests(unittest.TestCase):
    def test_actual_compiled_palette_matches_png_dimensions_alpha_bounds_and_preserved_hashes(self):
        evidence = json.loads((ROOT / "development_workflow/RUN_LOGS/Header-artwork-alpha-measurements.json").read_text())
        with tempfile.TemporaryDirectory(prefix="fruitfolio-header-art-metrics-") as temporary:
            work = Path(temporary)
            binary = work / "report"
            compile_result = subprocess.run([
                SWIFTC, "-parse-as-library", "-module-cache-path", str(work / "cache"),
                str(ROOT / "Fruitfolio/Core/Assets/FruitfolioAssetID.swift"),
                str(ROOT / "Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift"),
                str(ROOT / "Tools/report_header_artwork_metrics.swift"), "-o", str(binary)
            ], capture_output=True, text=True, timeout=90)
            self.assertEqual(compile_result.returncode, 0, compile_result.stderr)
            report = subprocess.run([str(binary)], capture_output=True, text=True, check=True, timeout=15)
            actual = json.loads(report.stdout)
        self.assertEqual({item["id"] for item in actual}, {item["id"] for item in evidence["assets"]})
        self.assertEqual(len(actual), 7)
        for item in evidence["assets"]:
            with self.subTest(asset=item["id"]):
                path = ROOT / item["path"]
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), item["sha256"])
                with Image.open(path) as image:
                    size = list(image.size)
                    threshold = evidence["alphaThresholdExclusive"]
                    box = image.convert("RGBA").getchannel("A").point(lambda value: 255 if value > threshold else 0).getbbox()
                self.assertIsNotNone(box)
                bounds = [box[0], box[1], box[2] - box[0], box[3] - box[1]]
                for record in actual:
                    if record["id"] == item["id"]:
                        self.assertEqual(record["pixels"], size)
                        self.assertEqual(record["visibleAlphaBounds"], bounds)
                self.assertEqual(item["pixels"], size)
                self.assertEqual(item["visibleAlphaBounds"], bounds)
