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
INLINE_HEAD = re.compile(
    r"^(?P<ts>\d{4}-\d{2}-\d{2}T\S+)\s+(?P<id>[A-Za-z]\w+)\s+(?P<rest>.*)$"
)
EXIT_LINE = re.compile(r"(?:exit:\s*|exit=)(-?\d+)")
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


def parse_log_blocks(text: str) -> dict[str, dict]:
    blocks: dict[str, dict] = {}
    current: dict | None = None

    def store(block: dict | None) -> None:
        if block:
            blocks[block["id"]] = block

    for raw in text.replace("\r\n", "\n").split("\n"):
        line = raw.rstrip()
        block_match = BLOCK_HEAD.match(line)
        inline_match = None if block_match else INLINE_HEAD.match(line)
        if block_match:
            store(current)
            current = _new_block(block_match.group("id"))
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
        if not text or SKIP_LINE.search(text):
            continue
        if text.startswith("command:") or text.startswith("command="):
            continue
        if text.startswith("exit:") or text.startswith("started:"):
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


def render_html(model: dict) -> str:
    badge = "Success" if model["success"] else "Failed"
    badge_class = "ok" if model["success"] else "bad"
    version = ""
    if model["version"]:
        version = (
            f"v{html.escape(model['version'])}+{html.escape(model['build'])}"
            if model["build"]
            else f"v{html.escape(model['version'])}"
        )
    stats = [
        (str(len(model["rows"])), "jobs"),
        (str(model["done"]), "done"),
    ]
    if model["failed"]:
        stats.append((str(model["failed"]), "failed"))
    if model["skipped"]:
        stats.append((str(model["skipped"]), "skipped"))
    stats.append((html.escape(model["total"]), "total"))
    stat_html = "".join(
        f'<li><strong>{value}</strong><span>{label}</span></li>'
        for value, label in stats
    )
    job_html = []
    for index, row in enumerate(model["rows"], start=1):
        note = html.escape(row["notes"][0]) if row["notes"] else ""
        job_html.append(
            "<li class='job'>"
            f"<span class='n'>{index:02d}</span>"
            "<div class='copy'>"
            f"<p class='name'>{html.escape(row['name'])}</p>"
            f"{f'<p class="note">{note}</p>' if note else ''}"
            "</div>"
            f"<span class='pill {row['status'].lower()}'>{row['status']}</span>"
            f"<span class='time'>{html.escape(row['duration'] or '-')}</span>"
            "</li>"
        )
    notes_html = ""
    extra = [item for item in model["notes"] if item[2] == "FAIL"]
    if model["excerpt"]:
        notes_html = (
            "<section class='card issue'>"
            "<h2>Issue</h2>"
            f"<p>{html.escape(model['excerpt'])}</p>"
            "</section>"
        )
    elif extra:
        items = "".join(
            f"<li><strong>{html.escape(name)}</strong> {html.escape(line)}</li>"
            for name, line, _status in extra[:4]
        )
        notes_html = (
            f"<section class='card'><h2>Watch</h2>"
            f"<ul class='notes'>{items}</ul></section>"
        )
    files_html = ""
    if model["files"]:
        items = "".join(f"<li>{html.escape(name)}</li>" for name in model["files"])
        files_html = (
            f"<section class='card'><h2>Files</h2>"
            f"<ul class='files'>{items}</ul></section>"
        )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Fluship {html.escape(model['app'])} {version}</title>
  <style>
    {font_css()}
    :root {{
      --ink: #12151c;
      --muted: #5d6573;
      --line: #e4e7ee;
      --paper: #f6f7fb;
      --navy: #121826;
      --blue: #3d7dff;
      --ok: #1ea36a;
      --bad: #e24b66;
      --skip: #8a8394;
    }}
    * {{ box-sizing: border-box; }}
    @page {{ size: A4; margin: 12mm 11mm 14mm; }}
    html, body {{
      margin: 0;
      background: #fff;
      color: var(--ink);
      font-family: "IBM Plex Sans", "Segoe UI", sans-serif;
      font-size: 12.5px;
      line-height: 1.45;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }}
    .sheet {{ width: 100%; }}
    header.hero {{
      background: var(--navy);
      color: #fff;
      border-radius: 18px;
      padding: 22px 24px 18px;
    }}
    .kicker {{
      margin: 0 0 8px;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      font-size: 10px;
      color: #8fb4ff;
      font-weight: 600;
    }}
    .hero-row {{
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      gap: 16px;
    }}
    h1 {{
      margin: 0;
      font-size: 28px;
      letter-spacing: -0.03em;
      font-weight: 600;
    }}
    .ver {{
      margin: 6px 0 0;
      color: #c5d0e6;
      font-family: "IBM Plex Mono", ui-monospace, monospace;
      font-size: 12px;
    }}
    .badge {{
      border-radius: 999px;
      padding: 7px 12px;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: #fff;
    }}
    .badge.ok {{ background: var(--ok); }}
    .badge.bad {{ background: var(--bad); }}
    .stats {{
      display: flex;
      gap: 18px;
      list-style: none;
      margin: 18px 0 0;
      padding: 14px 0 0;
      border-top: 1px solid rgba(255,255,255,0.1);
    }}
    .stats strong {{
      display: block;
      font-size: 16px;
      letter-spacing: -0.02em;
    }}
    .stats span {{ color: #9aa6bd; font-size: 10px; text-transform: uppercase; letter-spacing: 0.08em; }}
    h2 {{
      margin: 0 0 10px;
      font-size: 11px;
      letter-spacing: 0.12em;
      text-transform: uppercase;
      color: var(--blue);
    }}
    .card {{
      margin-top: 14px;
      padding: 14px 16px 8px;
      border: 1px solid var(--line);
      border-radius: 16px;
      background: #fff;
    }}
    .jobs {{ list-style: none; margin: 0; padding: 0; }}
    .job {{
      display: grid;
      grid-template-columns: 28px 1fr auto auto;
      gap: 10px;
      align-items: center;
      padding: 10px 4px;
      border-bottom: 1px solid var(--paper);
    }}
    .job:last-child {{ border-bottom: 0; }}
    .n {{
      color: var(--muted);
      font-family: "IBM Plex Mono", ui-monospace, monospace;
      font-size: 11px;
    }}
    .name {{ margin: 0; font-weight: 600; font-size: 13px; }}
    .note {{
      margin: 3px 0 0;
      color: var(--muted);
      font-size: 11px;
    }}
    .pill {{
      min-width: 52px;
      text-align: center;
      border-radius: 999px;
      padding: 4px 8px;
      font-size: 10px;
      font-weight: 600;
      letter-spacing: 0.04em;
    }}
    .pill.done {{ color: var(--ok); background: #e8f8f0; }}
    .pill.fail {{ color: var(--bad); background: #fdecef; }}
    .pill.skip {{ color: var(--skip); background: var(--paper); }}
    .time {{
      min-width: 52px;
      text-align: right;
      color: var(--muted);
      font-family: "IBM Plex Mono", ui-monospace, monospace;
      font-size: 11px;
    }}
    .issue {{ background: #fff5f7; border-color: #f7c8d1; }}
    .issue p, .notes, .files {{ margin: 0 0 10px; padding: 0; color: var(--ink); }}
    .notes, .files {{ list-style: none; }}
    .notes li, .files li {{ margin: 0 0 8px; color: var(--muted); }}
    .files li {{ font-family: "IBM Plex Mono", ui-monospace, monospace; font-size: 11px; color: var(--ink); }}
    footer {{
      margin-top: 16px;
      color: var(--muted);
      font-size: 10px;
    }}
  </style>
</head>
<body>
  <article class="sheet">
    <header class="hero">
      <p class="kicker">Fluship report</p>
      <div class="hero-row">
        <div>
          <h1>{html.escape(model['app'])}</h1>
          <p class="ver">{version}</p>
        </div>
        <span class="badge {badge_class}">{badge}</span>
      </div>
      <ul class="stats">{stat_html}</ul>
    </header>
    <section class="card">
      <h2>Progress</h2>
      <ol class="jobs">{''.join(job_html)}</ol>
    </section>
    {notes_html}
    {files_html}
    <footer>Full command output stays in {html.escape(model['log_name'])}. This page is the readable report.</footer>
  </article>
</body>
</html>
"""


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
