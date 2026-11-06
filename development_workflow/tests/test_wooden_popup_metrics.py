"""Compare genuine compiled wooden-popup metadata to unchanged founder artwork."""
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

@unittest.skipUnless(SWIFTC and Image, "Actual Swift compiler and Pillow required")
class WoodenPopupMetricsTests(unittest.TestCase):
    def test_compiled_geometry_matches_preserved_wooden_png(self):
        evidence = json.loads((ROOT / "development_workflow/RUN_LOGS/Wooden-popup-artwork-measurement.json").read_text())
        path = ROOT / evidence["path"]
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), evidence["sha256"])
        with Image.open(path) as image:
            pixels = list(image.size)
            bounds = image.convert("RGBA").getchannel("A").point(lambda value: 255 if value > 12 else 0).getbbox()
        self.assertEqual(pixels, evidence["pixels"])
        self.assertEqual(list(bounds), evidence["alphaBoundsExclusiveMax"])
        with tempfile.TemporaryDirectory(prefix="fruitfolio-wooden-metrics-") as temporary:
            work = Path(temporary)
            binary = work / "report"
            built = subprocess.run([SWIFTC, "-parse-as-library", "-module-cache-path", str(work / "cache"),
                                    str(ROOT / "Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift"),
                                    str(ROOT / "Tools/report_wooden_popup_metrics.swift"), "-o", str(binary)],
                                   capture_output=True, text=True, timeout=90)
            self.assertEqual(built.returncode, 0, built.stderr)
            report = json.loads(subprocess.check_output([str(binary)], text=True, timeout=15))
        self.assertEqual(report["pixels"], pixels)
        self.assertEqual(report["normalizedWritingRect"], evidence["normalizedWritingRect"])
        x, y, width, height = report["normalizedWritingRect"]
        # Visually reviewed reference exclusion: no rope, top screw or outer edge.
        self.assertGreaterEqual(y * pixels[1], 232)
        self.assertLessEqual((y + height) * pixels[1], 450)
        self.assertGreaterEqual(x * pixels[0], 64)
        self.assertLessEqual((x + width) * pixels[0], 530)
