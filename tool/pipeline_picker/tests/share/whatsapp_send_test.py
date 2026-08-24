#!/usr/bin/env python3
"""Tests for whatsapp_send.py. Does not open WhatsApp."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

import whatsapp_send as wa


class FakeHost:
    def __init__(self, copy_files: bool = True, open_chat: bool = True) -> None:
        self.copy_files_ok = copy_files
        self.open_chat_ok = open_chat
        self.files: list[str] = []
        self.texts: list[str] = []
        self.opened: list[str] = []
        self.calls: list[str] = []

    def copy_files(self, paths: list[str]) -> bool:
        self.calls.append("copy_files")
        self.files = list(paths)
        return self.copy_files_ok

    def copy_text(self, text: str) -> bool:
        self.calls.append("copy_text")
        self.texts.append(text)
        return True

    def open_chat(self, phone: str) -> bool:
        self.calls.append("open_chat")
        self.opened.append(phone)
        return self.open_chat_ok

    def activate(self) -> bool:
        self.calls.append("activate")
        return True

    def clear_composer(self) -> bool:
        self.calls.append("clear")
        return True

    def paste(self) -> bool:
        self.calls.append("paste")
        return True

    def press_send(self) -> bool:
        self.calls.append("send")
        return True


class WhatsAppSendTest(unittest.TestCase):
    def test_number_and_chat_uri(self) -> None:
        self.assertEqual(wa.digits_only("+92 309-6547269"), "923096547269")
        self.assertTrue(wa.is_valid_number("+923096547269"))
        self.assertFalse(wa.is_valid_number("123"))
        uri = wa.desktop_chat_uri("+923096547269")
        self.assertEqual(uri, "whatsapp://send?phone=923096547269")
        self.assertNotIn("text=", uri)

    def test_existing_files(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            pdf = Path(folder) / "pipeline-report.pdf"
            pdf.write_bytes(b"%PDF-1.4")
            missing = str(Path(folder) / "nope.apk")
            found = wa.existing_files([str(pdf), missing, str(pdf)])
            self.assertEqual(found, [str(pdf)])

    def test_share_files_before_caption(self) -> None:
        host = FakeHost()
        with tempfile.TemporaryDirectory() as folder:
            pdf = Path(folder) / "pipeline-report.pdf"
            pdf.write_bytes(b"%PDF-1.4")
            result = wa.share(
                host,
                "+923096547269",
                "Fluship: Reelstay v1.8.2+8206 failed.\nPDF report and any APKs are attached.",
                [str(pdf)],
                send=True,
                sleep=lambda _: None,
            )
        self.assertEqual(result, "sent")
        self.assertEqual(host.opened, ["923096547269"])
        self.assertTrue(host.files[0].endswith("pipeline-report.pdf"))
        self.assertIn("Fluship:", host.texts[0])
        self.assertLess(host.calls.index("copy_files"), host.calls.index("copy_text"))
        self.assertLess(host.calls.index("copy_files"), host.calls.index("send"))
        self.assertEqual(host.calls.count("copy_files"), 1)
        self.assertIn("clear", host.calls)
        self.assertIn("paste", host.calls)

    def test_text_only_sends_caption_without_files(self) -> None:
        host = FakeHost()
        result = wa.share(
            host,
            "+923096547269",
            "Fluship: Reelstay still running.",
            [],
            send=True,
            sleep=lambda _: None,
            text_only=True,
        )
        self.assertEqual(result, "sent")
        self.assertEqual(host.files, [])
        self.assertEqual(host.texts, ["Fluship: Reelstay still running."])
        self.assertNotIn("copy_files", host.calls)
        self.assertIn("copy_text", host.calls)
        self.assertIn("send", host.calls)

    def test_no_files_and_no_chat(self) -> None:
        self.assertEqual(
            wa.share(FakeHost(), "+923096547269", "x", [], sleep=lambda _: None),
            "no-files",
        )
        self.assertEqual(
            wa.share_text(FakeHost(), "+923096547269", "  ", sleep=lambda _: None),
            "no-text",
        )
        with tempfile.TemporaryDirectory() as folder:
            pdf = Path(folder) / "pipeline-report.pdf"
            pdf.write_bytes(b"%PDF-1.4")
            result = wa.share(
                FakeHost(open_chat=False),
                "+923096547269",
                "x",
                [str(pdf)],
                sleep=lambda _: None,
            )
        self.assertEqual(result, "no-whatsapp")

    def test_host_dispatch(self) -> None:
        self.assertIsInstance(wa.host_for("darwin"), wa.MacHost)
        self.assertIsInstance(wa.host_for("win32"), wa.WindowsHost)
        self.assertIsInstance(wa.host_for("linux"), wa.LinuxHost)

    def test_dry_run_cli(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            pdf = Path(folder) / "pipeline-report.pdf"
            pdf.write_bytes(b"%PDF-1.4")
            code = wa.main(
                [
                    "--number",
                    "+923096547269",
                    "--caption",
                    "hi",
                    "--file",
                    str(pdf),
                    "--dry-run",
                ]
            )
        self.assertEqual(code, 0)

    def test_dry_run_text_only(self) -> None:
        code = wa.main(
            [
                "--number",
                "+923096547269",
                "--text",
                "Fluship still running",
                "--dry-run",
            ]
        )
        self.assertEqual(code, 0)

    def test_text_only_flag_with_caption_file(self) -> None:
        with tempfile.TemporaryDirectory() as folder:
            caption = Path(folder) / "caption.txt"
            caption.write_text("Fluship:\nstill running\n", encoding="utf-8")
            code = wa.main(
                [
                    "--number",
                    "+923096547269",
                    "--caption-file",
                    str(caption),
                    "--text-only",
                    "--dry-run",
                ]
            )
        self.assertEqual(code, 0)


if __name__ == "__main__":
    unittest.main()
