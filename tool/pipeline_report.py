#!/usr/bin/env python3
"""Build the Fluship pipeline report.

Reads logs.txt, keeps short useful notes, writes HTML, then prints a PDF.
Full logs stay in logs.txt. They are not dumped into the PDF.
"""

from __future__ import annotations

import argparse
import base64
import html
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Callable

ROOT = Path(__file__).resolve().parent
FONTS = ROOT / "pipeline_picker" / "web" / "fonts"
CATALOG = ROOT / "pipeline_picker" / "catalog" / "catalog.dart"
MAX_BLOCK_LINES = 80

_TITLE_RE = re.compile(
    r"'(\w+)':\s*StepCopy\(\s*'((?:\\'|[^'])*)'",
)

SKIP_LINE = re.compile(
    r"("
    r"^\s*$"
    r"|pid="
    r"|Downloading packages"
    r"|Resolving dependencies"
    r"|Got dependencies"
    r"|incompatible with dependency"
    r"|flutter pub outdated"
    r"|Waiting for another flutter command"
    r"|%PDF"
    r"|^\d+ 0 obj"
    r"|^BT$|^ET$|^T\*$"
    r"|/F\d+\s+\d+\s+Tf"
    r"|whatsapp://send"
    r")",
    re.I,
)

PASSWORD = re.compile(
    r'(appPassword|app_password|password)["\s:=]+[^\s,"]+',
    re.I,
)

BLOCK_HEAD = re.compile(r"^\[(?P<ts>[^\]]+)\]\s+(?P<id>[A-Za-z]\w*)\s*$")
# Agents also write plain banners such as "===== buildSplits =====" and a
# matching "===== buildSplits done =====" when the job ends. Build tools print
# lookalikes such as "====== BUILD FAILED ======", so the id must be a real
# catalog step before this counts as a header.
SECTION_HEAD = re.compile(r"^=+\s*(?P<id>[A-Za-z]\w*)\b[^=]*=*$")
DECORATION = re.compile(r"^[=*~_-]{3,}$")
BANNER_EDGE = re.compile(r"^[=*]{2,}\s*|\s*[=*]{2,}$")
INLINE_HEAD = re.compile(
    r"^(?P<ts>\d{4}-\d{2}-\d{2}T\S+)\s+(?P<id>[A-Za-z]\w+)\s+(?P<rest>.*)$"
)
EXIT_LINE = re.compile(r"(?:exit:\s*|exit=)(-?\d+)")
NOISE_PREFIX = re.compile(
    r"^(exit|started|started_at|ended_at|result|elapsed)\b[:=]?",
    re.I,
)
ELAPSED_LINE = re.compile(r"elapsed=([0-9hm.]+s|[0-9]+m(?:[0-9.]+s)?)")

_FONT_CSS: str | None = None
NotePicker = Callable[[list[str], bool], list[str]]


def load_titles(path: Path | None = None) -> dict[str, str]:
    catalog = path or CATALOG
    if not catalog.exists():
        return {}
    return {
        key: title.replace(r"\'", "'")
        for key, title in _TITLE_RE.findall(catalog.read_text(encoding="utf-8"))
    }


TITLES = load_titles()


def normalize_id(raw: str) -> str:
    text = raw.strip()
    if not text:
        return text
    return text[0].lower() + text[1:]


def human_name(step_id: str) -> str:
    key = normalize_id(step_id)
    title = TITLES.get(key)
    if title:
        return title
    spaced = re.sub(r"([a-z])([A-Z])", r"\1 \2", step_id).strip()
    return spaced[:1].upper() + spaced[1:] if spaced else step_id


def redact(text: str) -> str:
    return PASSWORD.sub("password [redacted]", text)


def parse_steps(raw: str) -> list[dict]:
    out = []
    for part in raw.split(","):
        bits = part.strip().split(":")
        if not bits or not bits[0].strip():
            continue
        step_id = normalize_id(bits[0])
        result = bits[1].strip() if len(bits) > 1 else ""
        duration = ":".join(bits[2:]).strip() if len(bits) > 2 else ""
        out.append({"id": step_id, "result": result, "duration": duration})
    return out


def mark(result: str) -> str:
    key = result.lower()
    if key in {"fail", "failed", "error"}:
        return "FAIL"
    if key in {"skip", "skipped"}:
        return "SKIP"
    return "DONE"


def parse_seconds(text: str) -> float:
    text = text.strip().lower()
    if not text:
        return 0.0
    total = 0.0
    for amount, unit in re.findall(r"(\d+(?:\.\d+)?)([hms])", text):
        value = float(amount)
        if unit == "h":
            total += value * 3600
        elif unit == "m":
            total += value * 60
        else:
            total += value
    return total


def format_total(seconds: float) -> str:
    if seconds <= 0:
        return "-"
    if seconds < 60:
        return f"{seconds:.1f}s".replace(".0s", "s")
    minutes = int(seconds // 60)
    rest = seconds - minutes * 60
    if rest < 1:
        return f"{minutes}m"
    return f"{minutes}m {rest:.0f}s"


def section_head_id(line: str) -> str:
    """Return the step id for an agent banner line, or "" when the line only
    looks like one. Build tools emit "====== BUILD FAILED ======", which must
    stay inside the running job instead of opening a bogus block."""
    match = SECTION_HEAD.match(line)
    if not match:
        return ""
    step_id = match.group("id")
    if TITLES and normalize_id(step_id) not in TITLES:
        return ""
    return step_id


def parse_log_blocks(text: str) -> dict[str, dict]:
    blocks: dict[str, dict] = {}
    current: dict | None = None

    def store(block: dict | None) -> None:
        """A job can appear twice, once on start and again on finish or retry.
        Merge instead of overwrite so no output is lost."""
        if not block:
            return
        prior = blocks.get(block["id"])
        if prior is None:
            blocks[block["id"]] = block
            return
        for line in block["lines"]:
            _append_line(prior, line)

    for raw in text.replace("\r\n", "\n").split("\n"):
        line = raw.rstrip()
        block_match = BLOCK_HEAD.match(line)
        head_id = block_match.group("id") if block_match else section_head_id(line)
        inline_match = None if head_id else INLINE_HEAD.match(line)
        if head_id:
            store(current)
            current = _new_block(head_id)
            continue
        if inline_match:
            rest = inline_match.group("rest")
            if rest.startswith("command=") or rest.startswith("exit="):
                store(current)
                current = _new_block(inline_match.group("id"))
                _append_line(current, line)
                continue
        if current is None:
            continue
        _append_line(current, line)
    store(current)
    return blocks


def _new_block(step_id: str) -> dict:
    return {
        "id": normalize_id(step_id),
        "lines": [],
        "exit": "",
        "elapsed": "",
        "empty_commit": False,
    }


def _append_line(block: dict, line: str) -> None:
    lines = block["lines"]
    lines.append(line)
    overflow = len(lines) - MAX_BLOCK_LINES
    if overflow > 0:
        del lines[:overflow]
    _fill_meta(block, line)


def _fill_meta(block: dict, line: str) -> None:
    exit_match = EXIT_LINE.search(line)
    if exit_match:
        block["exit"] = exit_match.group(1)
    elapsed_match = ELAPSED_LINE.search(line)
    if elapsed_match:
        block["elapsed"] = elapsed_match.group(1)
    if "nothing to commit" in line.lower():
        block["empty_commit"] = True


def _clean_lines(lines: list[str]) -> list[str]:
    cleaned = []
    for line in lines:
        text = redact(line.strip())
        if DECORATION.match(text):
            continue
        text = BANNER_EDGE.sub("", text).strip()
        if not text or SKIP_LINE.search(text):
            continue
        if text.startswith("command:") or text.startswith("command="):
            continue
        if text.startswith("$ ") or text.startswith("output:"):
            continue
        if NOISE_PREFIX.match(text):
            continue
        if re.match(r"^\d{4}-\d{2}-\d{2}T", text):
            continue
        if text.startswith("[20") and "]" in text[:28]:
            continue
        text = (
            text.replace("\u2192", "->")
            .replace("\u2014", "-")
            .replace("\u2013", "-")
        )
        if len(text) > 110:
            text = text[:109] + "."
        cleaned.append(text)
    return cleaned


def _first_matching(cleaned: list[str], predicate) -> list[str]:
    return [line for line in cleaned if predicate(line)]


def _note_test(cleaned: list[str], failed: bool) -> list[str]:
    for line in reversed(cleaned):
        if "All tests passed" in line or "Some tests failed" in line:
            return [line]
        match = re.search(r"(\+\d+ -+\d+:.+)", line)
        if match:
            return [match.group(1)]
    return ["Test run finished."] if cleaned else []


def _note_analyze(cleaned: list[str], failed: bool) -> list[str]:
    for line in reversed(cleaned):
        if "No issues found" in line or "issue" in line.lower():
            return [line]
    return cleaned[-1:] if cleaned else []


def _note_format(cleaned: list[str], failed: bool) -> list[str]:
    return _first_matching(cleaned, lambda line: "Formatted" in line)[:1]


def _note_pub(cleaned: list[str], failed: bool) -> list[str]:
    return _first_matching(
        cleaned,
        lambda line: "Changed" in line or "No dependencies" in line,
    )[:2]


def _note_version(cleaned: list[str], failed: bool) -> list[str]:
    return _first_matching(cleaned, lambda line: "version:" in line)[:1]


def _note_commit(cleaned: list[str], failed: bool) -> list[str]:
    if any("nothing to commit" in line.lower() for line in cleaned):
        return ["Nothing to commit."]
    return _first_matching(
        cleaned,
        lambda line: re.search(r"\[[\w/.-]+ [0-9a-f]{7,}\]", line)
        or "file changed" in line,
    )[:2]


def _note_pull(cleaned: list[str], failed: bool) -> list[str]:
    return _first_matching(
        cleaned,
        lambda line: "up to date" in line
        or "Updating" in line
        or "Fast-forward" in line,
    )[:2]


def _note_silent(cleaned: list[str], failed: bool) -> list[str]:
    return []


def _note_default(cleaned: list[str], failed: bool) -> list[str]:
    limit = 6 if failed else 3
    useful = [
        line
        for line in cleaned
        if re.search(r"error|fail|exception|error:", line, re.I)
    ]
    if useful:
        return useful[-limit:]
    return cleaned[-limit:]


NOTE_PICKERS: dict[str, NotePicker] = {
    "test": _note_test,
    "analyze": _note_analyze,
    "format": _note_format,
    "pubGet": _note_pub,
    "pubUpgrade": _note_pub,
    "bumpVersion": _note_version,
    "preCommit": _note_commit,
    "postCommit": _note_commit,
    "prePull": _note_pull,
    "clean": _note_silent,
    "whatsappShare": _note_silent,
}


def pick_notes(
    step_id: str,
    lines: list[str],
    failed: bool,
    empty_commit: bool = False,
) -> list[str]:
    if empty_commit and step_id in {"preCommit", "postCommit"}:
        return ["Nothing to commit."]
    picker = NOTE_PICKERS.get(step_id, _note_default)
    return picker(_clean_lines(lines), failed)


NEXT_STEPS: dict[str, str] = {
    "bumpVersion": "Check the version line in pubspec.yaml, then rerun.",
    "preCommit": "Stage or discard the leftover changes, then commit again.",
    "postCommit": "Stage or discard the leftover changes, then commit again.",
    "prePull": "Resolve the merge conflict in the repo, then pull again.",
    "postPush": "Pull the remote branch, resolve the conflict, then push.",
    "clean": "Close anything holding the build folder, then clean again.",
    "pubGet": "Fix the version conflict in pubspec.yaml, then run pub get.",
    "pubUpgrade": "Fix the version conflict in pubspec.yaml, then upgrade.",
    "format": "Fix the file dart format could not parse.",
    "analyze": "Fix the analyzer issues, then run flutter analyze again.",
    "test": "Fix the failing test, then run flutter test again.",
    "buildAab": "Read the Gradle error in the log, then rebuild the bundle.",
    "buildApk": "Read the Gradle error in the log, then rebuild the APK.",
    "buildSplits": "Read the Gradle error in the log, then rebuild the splits.",
    "podInstall": "Delete ios/Podfile.lock, then run pod install again.",
    "buildIpa": "Check signing in Xcode, then build the IPA again.",
    "collectAab": "The build produced no bundle. Rebuild before collecting.",
    "collectApk": "The build produced no APK. Rebuild before collecting.",
    "collectIpa": "The build produced no IPA. Rebuild before collecting.",
    "distPlayProduction": "Check the Play service account and package name.",
    "distPlayInternal": "Check the Play service account and package name.",
    "distAppStore": "Check the App Store API key and the .p8 path.",
    "distDrive": "Re-auth Drive in Fluship Settings, then upload again.",
    "slackNotify": "Check the Slack webhook URL, then notify again.",
    "report": "Check the Gmail address and app password, then resend.",
    "whatsappShare": "Grant Accessibility to the terminal, then share again.",
}

DEFAULT_NEXT_STEP = "Open the log at that job and fix the first error."


def slowest_jobs(rows: list[dict], limit: int = 3) -> list[dict]:
    """Longest jobs first, each with a share of the slowest for the bar width."""
    timed = [
        {
            "name": row["name"],
            "duration": row["duration"],
            "seconds": parse_seconds(row["duration"]),
        }
        for row in rows
        if parse_seconds(row["duration"]) > 0
    ]
    timed.sort(key=lambda item: item["seconds"], reverse=True)
    top = timed[:limit]
    peak = top[0]["seconds"] if top else 0.0
    for item in top:
        item["percent"] = round(item["seconds"] / peak * 100) if peak else 0
    return top


def build_summary(model: dict) -> dict:
    """One plain sentence about the run, plus the single next action."""
    rows = model["rows"]
    if not rows:
        return {"headline": "No jobs ran.", "detail": "", "next_step": ""}
    total = len(rows)
    done = model["done"]
    failures = [row for row in rows if row["status"] == "FAIL"]
    if failures:
        first = failures[0]
        after = f" after {first['duration']}" if first["duration"] else ""
        headline = f"{done} of {total} jobs finished. {first['name']} failed{after}."
        next_step = NEXT_STEPS.get(first["id"], DEFAULT_NEXT_STEP)
    elif model["skipped"]:
        headline = (
            f"{done} of {total} jobs finished. {model['skipped']} were skipped."
        )
        next_step = ""
    else:
        headline = f"All {total} jobs finished."
        next_step = ""
    details = [f"Total job time {model['total']}."]
    slowest = slowest_jobs(rows, limit=1)
    if slowest:
        details.append(
            f"Slowest was {slowest[0]['name']} at {slowest[0]['duration']}."
        )
    if len(failures) > 1:
        details.append(f"{len(failures)} jobs failed in total.")
    return {
        "headline": headline,
        "detail": " ".join(details),
        "next_step": next_step,
    }


def _read_log(path: str) -> str:
    if not path:
        return ""
    file = Path(path)
    if not file.exists():
        return ""
    return file.read_text(encoding="utf-8", errors="replace")


def build_model(args: argparse.Namespace) -> dict:
    blocks = parse_log_blocks(_read_log(args.log))
    jobs = parse_steps(args.steps)
    if not jobs:
        jobs = [
            {
                "id": key,
                "result": "ok" if block.get("exit") in {"", "0"} else "fail",
                "duration": block.get("elapsed") or "",
            }
            for key, block in blocks.items()
            if key != "whatsappShare"
        ]
    rows = []
    notes = []
    for job in jobs:
        block = blocks.get(job["id"], {})
        duration = job["duration"] or block.get("elapsed") or ""
        result = job["result"]
        if not result:
            result = "ok" if block.get("exit") in {"", "0"} else "fail"
        if block.get("empty_commit"):
            result = "skip"
        status = mark(result)
        failed = status == "FAIL"
        note_lines = pick_notes(
            job["id"],
            block.get("lines", []),
            failed,
            empty_commit=bool(block.get("empty_commit")),
        )
        name = human_name(job["id"])
        rows.append(
            {
                "id": job["id"],
                "name": name,
                "status": status,
                "duration": duration,
                "notes": note_lines,
            }
        )
        notes.extend((name, line, status) for line in note_lines)
    files = [Path(item).name for item in args.files if item.strip()]
    done = sum(1 for row in rows if row["status"] == "DONE")
    failed = sum(1 for row in rows if row["status"] == "FAIL")
    skipped = sum(1 for row in rows if row["status"] == "SKIP")
    total = format_total(sum(parse_seconds(row["duration"]) for row in rows))
    excerpt = redact(args.error or "")
    if not excerpt:
        for _name, line, status in notes:
            if status == "FAIL":
                excerpt = line
                break
    return {
        "app": args.app or "App",
        "version": args.version or "",
        "build": args.build or "",
        "success": args.success != "false",
        "rows": rows,
        "notes": notes[:12],
        "files": files,
        "done": done,
        "failed": failed,
        "skipped": skipped,
        "total": total,
        "excerpt": excerpt[:240],
        "log_name": Path(args.log).name if args.log else "logs.txt",
        "stamp": datetime.now().strftime("%d %b %Y at %H:%M"),
    }


def _build_font_css() -> str:
    faces = []
    catalog = (
        ("IBM Plex Sans", "IBMPlexSans-Regular.woff2", 400),
        ("IBM Plex Sans", "IBMPlexSans-Medium.woff2", 500),
        ("IBM Plex Sans", "IBMPlexSans-SemiBold.woff2", 600),
        ("IBM Plex Mono", "IBMPlexMono-Regular.woff2", 400),
        ("IBM Plex Mono", "IBMPlexMono-Medium.woff2", 500),
    )
    for family, name, weight in catalog:
        path = FONTS / name
        if not path.exists():
            continue
        data = base64.b64encode(path.read_bytes()).decode("ascii")
        faces.append(
            f"@font-face{{font-family:'{family}';src:url(data:font/woff2;base64,{data}) "
            f"format('woff2');font-weight:{weight};font-style:normal;font-display:swap;}}"
        )
    return "\n".join(faces)


def font_css() -> str:
    global _FONT_CSS
    if _FONT_CSS is None:
        _FONT_CSS = _build_font_css()
    return _FONT_CSS


_CSS = """
:root {
  --bg: #0b0f16;
  --surface: #141a24;
  --raised: #1b2331;
  --ink: #e8edf6;
  --muted: #8d99ad;
  --line: #26303f;
  --blue: #6ea8ff;
  --ok: #46d38a;
  --bad: #ff6b81;
  --skip: #8d99ad;
}
* { box-sizing: border-box; }
/* No page margin so the dark sheet reaches every edge. Padding lives on
   .page, and each page is a full A4 so Chrome paints the whole sheet. */
@page { size: A4; margin: 0; }
html, body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
  font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
  font-size: 12.5px;
  line-height: 1.45;
  -webkit-print-color-adjust: exact;
  print-color-adjust: exact;
}
.page {
  width: 210mm;
  min-height: 297mm;
  padding: 13mm 12mm 15mm;
  background: var(--bg);
}
.page.first { page-break-after: always; }
header.hero {
  background: linear-gradient(135deg, #17203040, #6ea8ff1f), var(--surface);
  border: 1px solid var(--line);
  color: var(--ink);
  border-radius: 18px;
  padding: 22px 24px 20px;
}
.kicker {
  margin: 0 0 8px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  font-size: 10px;
  color: var(--blue);
  font-weight: 600;
}
.hero-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
}
h1 { margin: 0; font-size: 30px; letter-spacing: -0.03em; font-weight: 600; }
.ver {
  margin: 6px 0 0;
  color: var(--muted);
  font-family: "IBM Plex Mono", ui-monospace, monospace;
  font-size: 12px;
}
.badge {
  border-radius: 999px;
  padding: 7px 13px;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #0b0f16;
  white-space: nowrap;
}
.badge.ok { background: var(--ok); }
.badge.bad { background: var(--bad); }
.lead {
  margin: 18px 0 0;
  padding-top: 16px;
  border-top: 1px solid var(--line);
  font-size: 16px;
  font-weight: 500;
  color: var(--ink);
  letter-spacing: -0.01em;
}
.sub { margin: 6px 0 0; color: var(--muted); font-size: 11.5px; }
.tiles {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 10px;
  list-style: none;
  margin: 14px 0 0;
  padding: 0;
}
.tiles li {
  border: 1px solid var(--line);
  border-radius: 14px;
  background: var(--surface);
  padding: 12px 12px 10px;
  text-align: center;
}
.tiles strong {
  display: block;
  font-size: 20px;
  letter-spacing: -0.03em;
  font-family: "IBM Plex Mono", ui-monospace, monospace;
}
.tiles span {
  color: var(--muted);
  font-size: 9.5px;
  text-transform: uppercase;
  letter-spacing: 0.09em;
}
.tiles li.bad strong { color: var(--bad); }
.tiles li.bad { border-color: #5a2733; background: #24151b; }
h2 {
  margin: 0 0 12px;
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--blue);
}
.card {
  margin-top: 14px;
  padding: 16px 18px 12px;
  border: 1px solid var(--line);
  border-radius: 16px;
  background: var(--surface);
}
.bars { list-style: none; margin: 0; padding: 0; }
.bars li {
  display: grid;
  grid-template-columns: 1fr 100px auto;
  gap: 12px;
  align-items: center;
  padding: 7px 0;
}
.bar-name { font-weight: 500; }
.track { background: var(--raised); border-radius: 999px; height: 8px; }
/* A sub-second job still gets a visible sliver. */
.fill {
  display: block;
  background: var(--blue);
  border-radius: 999px;
  height: 8px;
  min-width: 4px;
}
.bar-time {
  color: var(--muted);
  font-family: "IBM Plex Mono", ui-monospace, monospace;
  font-size: 11px;
  min-width: 52px;
  text-align: right;
}
.issue { background: #1d1319; border-color: #5a2733; }
.issue h2 { color: var(--bad); }
.who { margin: 0; font-weight: 600; font-size: 14px; }
.what {
  margin: 6px 0 0;
  color: var(--ink);
  font-family: "IBM Plex Mono", ui-monospace, monospace;
  font-size: 11px;
  word-break: break-word;
}
.next {
  margin: 12px 0 4px;
  padding-top: 10px;
  border-top: 1px solid #5a2733;
  color: var(--ink);
}
.next b {
  display: block;
  font-size: 9.5px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: var(--bad);
  margin-bottom: 3px;
}
.jobs { list-style: none; margin: 0; padding: 0; }
.job {
  display: grid;
  grid-template-columns: 28px 1fr auto 56px;
  gap: 10px;
  align-items: center;
  padding: 10px 4px;
  border-bottom: 1px solid var(--line);
}
.job:last-child { border-bottom: 0; }
.n {
  color: var(--muted);
  font-family: "IBM Plex Mono", ui-monospace, monospace;
  font-size: 11px;
}
.name { margin: 0; font-weight: 600; font-size: 13px; }
.note { margin: 3px 0 0; color: var(--muted); font-size: 11px; }
.pill {
  min-width: 52px;
  text-align: center;
  border-radius: 999px;
  padding: 4px 8px;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.04em;
}
.pill.done { color: var(--ok); background: #12291f; }
.pill.fail { color: var(--bad); background: #2a1620; }
.pill.skip { color: var(--skip); background: var(--raised); }
.time {
  text-align: right;
  color: var(--muted);
  font-family: "IBM Plex Mono", ui-monospace, monospace;
  font-size: 11px;
}
.files { list-style: none; margin: 0; padding: 0; }
.files li {
  margin: 0 0 7px;
  font-family: "IBM Plex Mono", ui-monospace, monospace;
  font-size: 11px;
}
.page-head {
  margin: 0 0 4px;
  font-size: 20px;
  letter-spacing: -0.02em;
  text-transform: none;
  color: var(--ink);
  font-weight: 600;
}
.page-sub { margin: 0 0 14px; color: var(--muted); font-size: 11px; }
footer { margin-top: 16px; color: var(--muted); font-size: 10px; }
"""


def version_label(model: dict) -> str:
    if not model["version"]:
        return ""
    if model["build"]:
        return f"v{model['version']}+{model['build']}"
    return f"v{model['version']}"


def _tiles_html(model: dict) -> str:
    tiles = [
        (str(len(model["rows"])), "jobs", False),
        (str(model["done"]), "done", False),
        (str(model["failed"]), "failed", bool(model["failed"])),
        (str(model["skipped"]), "skipped", False),
        (model["total"], "job time", False),
    ]
    return "".join(
        f'<li class="{"bad" if bad else ""}">'
        f"<strong>{html.escape(value)}</strong>"
        f"<span>{label}</span></li>"
        for value, label, bad in tiles
    )


def _bars_html(rows: list[dict]) -> str:
    slow = slowest_jobs(rows)
    if not slow:
        return ""
    items = "".join(
        f'<li><span class="bar-name">{html.escape(item["name"])}</span>'
        f'<span class="track"><span class="fill" style="width:{item["percent"]}%"></span></span>'
        f'<span class="bar-time">{html.escape(item["duration"])}</span></li>'
        for item in slow
    )
    return f'<section class="card"><h2>Where the time went</h2><ul class="bars">{items}</ul></section>'


def _issue_html(model: dict, summary: dict) -> str:
    failed = [row for row in model["rows"] if row["status"] == "FAIL"]
    if not failed and not model["excerpt"]:
        return ""
    who = failed[0]["name"] if failed else "Run"
    what = model["excerpt"] or "No error line was captured."
    next_step = summary["next_step"] or DEFAULT_NEXT_STEP
    return (
        '<section class="card issue"><h2>Issue</h2>'
        f'<p class="who">{html.escape(who)}</p>'
        f'<p class="what">{html.escape(what)}</p>'
        f'<p class="next"><b>Next step</b>{html.escape(next_step)}</p>'
        "</section>"
    )


def _files_html(model: dict) -> str:
    if not model["files"]:
        return ""
    items = "".join(f"<li>{html.escape(name)}</li>" for name in model["files"])
    return f'<section class="card"><h2>Attachments</h2><ul class="files">{items}</ul></section>'


def _jobs_html(rows: list[dict]) -> str:
    out = []
    for index, row in enumerate(rows, start=1):
        note = html.escape(row["notes"][0]) if row["notes"] else ""
        note_html = f'<p class="note">{note}</p>' if note else ""
        out.append(
            '<li class="job">'
            f'<span class="n">{index:02d}</span>'
            f'<div><p class="name">{html.escape(row["name"])}</p>{note_html}</div>'
            f'<span class="pill {row["status"].lower()}">{row["status"]}</span>'
            f'<span class="time">{html.escape(row["duration"] or "-")}</span>'
            "</li>"
        )
    return "".join(out)


def _cover_page(model: dict, summary: dict) -> str:
    badge = "Success" if model["success"] else "Failed"
    return (
        '<section class="page first">'
        '<header class="hero">'
        '<p class="kicker">Fluship release report</p>'
        '<div class="hero-row"><div>'
        f'<h1>{html.escape(model["app"])}</h1>'
        f'<p class="ver">{html.escape(version_label(model))}</p>'
        f'</div><span class="badge {"ok" if model["success"] else "bad"}">{badge}</span></div>'
        f'<p class="lead">{html.escape(summary["headline"])}</p>'
        f'<p class="sub">{html.escape(summary["detail"])}</p>'
        "</header>"
        f'<ul class="tiles">{_tiles_html(model)}</ul>'
        f"{_bars_html(model['rows'])}"
        f"{_issue_html(model, summary)}"
        f"{_files_html(model)}"
        f'<footer>Generated {html.escape(model["stamp"])}. '
        f'Job detail is on the next page.</footer>'
        "</section>"
    )


def _detail_page(model: dict) -> str:
    return (
        '<section class="page">'
        '<h2 class="page-head">Job detail</h2>'
        f'<p class="page-sub">{html.escape(model["app"])} '
        f'{html.escape(version_label(model))}, every job in run order.</p>'
        f'<section class="card"><ol class="jobs">{_jobs_html(model["rows"])}</ol></section>'
        f'<footer>Full command output stays in {html.escape(model["log_name"])}. '
        "This report keeps only the useful lines.</footer>"
        "</section>"
    )


def render_html(model: dict) -> str:
    summary = build_summary(model)
    title = f"Fluship {model['app']} {version_label(model)}".strip()
    return (
        "<!doctype html>\n"
        '<html lang="en">\n<head>\n<meta charset="utf-8">\n'
        f"<title>{html.escape(title)}</title>\n"
        f"<style>\n{font_css()}\n{_CSS}</style>\n"
        "</head>\n<body>\n"
        f"{_cover_page(model, summary)}\n{_detail_page(model)}\n"
        "</body>\n</html>\n"
    )


def find_chrome() -> str | None:
    env = os.environ.get("CHROME_PATH", "").strip()
    if env and Path(env).exists():
        return env
    candidates = [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge",
        "/usr/bin/google-chrome",
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
    ]
    for path in candidates:
        if Path(path).exists():
            return path
    for name in ("google-chrome", "chromium", "chromium-browser", "msedge"):
        found = shutil.which(name)
        if found:
            return found
    return None


def html_to_pdf(html_path: Path, pdf_path: Path) -> None:
    chrome = find_chrome()
    if not chrome:
        raise RuntimeError("Chrome is not installed. Cannot print HTML to PDF.")
    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    uri = html_path.resolve().as_uri()
    dest = f"--print-to-pdf={pdf_path}"
    attempts = (
        [chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer", dest, uri],
        [chrome, "--headless", "--disable-gpu", "--print-to-pdf-no-header", dest, uri],
    )
    last = ""
    for cmd in attempts:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if pdf_path.exists() and pdf_path.stat().st_size >= 64:
            return
        last = result.stderr or result.stdout
    raise RuntimeError(last or "Chrome did not write a PDF.")


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build a Fluship HTML/PDF pipeline report.")
    parser.add_argument("--log", default="")
    parser.add_argument("--pdf", default="")
    parser.add_argument("--html", default="")
    parser.add_argument("--app", default="App")
    parser.add_argument("--version", default="")
    parser.add_argument("--build", default="")
    parser.add_argument("--success", default="true")
    parser.add_argument("--steps", default="")
    parser.add_argument("--error", default="")
    parser.add_argument("--files", default="")
    parser.add_argument("--html-only", action="store_true")
    args = parser.parse_args(argv)
    args.files = [part.strip() for part in args.files.split(",") if part.strip()]
    return args


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    page = render_html(build_model(args))
    html_path = Path(args.html) if args.html else None
    if html_path is None and args.pdf:
        html_path = Path(args.pdf).with_suffix(".html")
    if html_path is None:
        sys.stdout.write(page)
        return 0
    html_path.parent.mkdir(parents=True, exist_ok=True)
    html_path.write_text(page, encoding="utf-8")
    sys.stdout.write(f"HTML: {html_path}\n")
    if args.html_only or not args.pdf:
        return 0
    html_to_pdf(html_path, Path(args.pdf))
    sys.stdout.write(f"PDF: {args.pdf}\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (RuntimeError, OSError) as error:
        sys.stderr.write(f"{error}\n")
        raise SystemExit(1)
