#!/usr/bin/env python3
"""Tests for pipeline_report.py. No Chrome required."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

import pipeline_report as report


SAMPLE_LOG = """
[2026-08-24T19:22:13Z] bumpVersion
command: set pubspec.yaml version to 1.8.2+8205
exit: 0
output:
5:version: 1.8.2+8205

[2026-08-24T19:22:56Z] pubUpgrade
command: flutter pub upgrade
exit: 0
output:
Resolving dependencies...
Downloading packages...
Changed 15 dependencies!

[2026-08-24T19:42:27Z] test
command: flutter test
exit: 0
00:00 +1: some_test.dart
00:12 +120: All tests passed!

[2026-08-24T19:50:00Z] buildAab
command: flutter build aab --release
exit: 1
output:
appPassword=super-secret failed to sign
Gradle failed.
"""


class PipelineReportTest(unittest.TestCase):
    def test_parse_and_summarize(self) -> None:
        args = report.parse_args(
            [
                "--app",
                "Reelstay",
                "--version",
                "1.8.2",
                "--build",
                "8205",
                "--success",
                "false",
                "--steps",
                "BumpVersion:ok:0.3s,PubUpgrade:ok:13.3s,Test:ok:49.9s,BuildAab:fail:3m",
                "--files",
                "pipeline-report.pdf,app.apk",
            ]
        )
        with tempfile.TemporaryDirectory() as folder:
            log = Path(folder) / "logs.txt"
            log.write_text(SAMPLE_LOG, encoding="utf-8")
            args.log = str(log)
            model = report.build_model(args)
        self.assertEqual(model["app"], "Reelstay")
        self.assertEqual(len(model["rows"]), 4)
        names = [row["name"] for row in model["rows"]]
        self.assertEqual(names[0], "Set app version")
        self.assertEqual(model["rows"][3]["status"], "FAIL")
        notes = " ".join(line for _name, line, _status in model["notes"])
        self.assertIn("version: 1.8.2+8205", notes)
        self.assertIn("Changed 15 dependencies", notes)
        self.assertIn("All tests passed", notes)
        self.assertNotIn("00:00 +1", notes)
        self.assertNotIn("Downloading packages", notes)
        self.assertNotIn("super-secret", model["excerpt"])
        self.assertIn("[redacted]", model["excerpt"])
        page = report.render_html(model)
        self.assertIn("FLUSHIP", page.upper() or "Fluship")
        self.assertIn("Reelstay", page)
        self.assertIn("Set app version", page)
        self.assertIn("IBM Plex Sans", page)
        self.assertNotIn("\u2014", page)
        self.assertNotIn("00:00 +1: some_test.dart", page)
        self.assertLess(page.count("<li class='job'>"), 8)

    def test_titles_come_from_catalog(self) -> None:
        titles = report.load_titles()
        self.assertEqual(titles["clean"], "Clean old build files")
        self.assertEqual(titles["whatsappShare"], "Send PDF and APKs on WhatsApp")
        self.assertEqual(report.human_name("buildAab"), "Build Play bundle (AAB)")

    def test_html_only_writes_file(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            html_path = Path(folder) / "report.html"
            code = report.main(
                [
                    "--html",
                    str(html_path),
                    "--html-only",
                    "--app",
                    "Demo",
                    "--steps",
                    "Clean:ok:1s",
                ]
            )
            self.assertEqual(code, 0)
            self.assertTrue(html_path.exists())
            text = html_path.read_text(encoding="utf-8")
            self.assertIn("Clean old build files", text)


if __name__ == "__main__":
    unittest.main()
