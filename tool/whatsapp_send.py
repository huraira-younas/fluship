#!/usr/bin/env python3
"""Send Fluship PDF and APKs through WhatsApp Desktop.

No Cloud API. No AppleScript UI. The chat URI never includes text.
macOS copies a Finder file list. Windows uses CF_HDROP. Linux uses
text/uri-list. Python then pastes into WhatsApp Desktop and sends.
"""

from __future__ import annotations

import argparse
import ctypes
import ctypes.util
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import Callable, Protocol
from urllib.parse import quote

def _seconds(name: str, default: float) -> float:
    """Timings are tunable without a code edit. Bad values fall back."""
    try:
        value = float(os.environ.get(name, "").strip())
    except ValueError:
        return default
    return value if value >= 0 else default


# Chat keeps loading after the URI, even when WhatsApp is already open.
CHAT_OPEN_SECONDS = _seconds("FLUSHIP_WA_CHAT_OPEN", 5.0)
FOCUS_SECONDS = _seconds("FLUSHIP_WA_FOCUS", 0.8)
CLEAR_SECONDS = _seconds("FLUSHIP_WA_CLEAR", 0.4)
FILE_PASTE_SECONDS = _seconds("FLUSHIP_WA_FILE_PASTE", 3.5)
CAPTION_PASTE_SECONDS = _seconds("FLUSHIP_WA_CAPTION_PASTE", 1.2)
SEND_SECONDS = _seconds("FLUSHIP_WA_SEND", 1.5)
SEND_RETRY_SECONDS = _seconds("FLUSHIP_WA_SEND_RETRY", 1.2)
# Keystrokes land in the wrong order when they are posted back to back.
KEY_GAP_SECONDS = _seconds("FLUSHIP_WA_KEY_GAP", 0.08)


def digits_only(raw: str) -> str:
    return "".join(ch for ch in raw if ch.isdigit())


def is_valid_number(raw: str) -> bool:
    return 10 <= len(digits_only(raw)) <= 15


def desktop_chat_uri(number: str) -> str:
    return f"whatsapp://send?phone={digits_only(number)}"


def existing_files(paths: list[str]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for raw in paths:
        path = str(Path(raw).expanduser())
        if not path or path in seen or not Path(path).is_file():
            continue
        seen.add(path)
        out.append(path)
    return out


def run_cmd(cmd: list[str], **kwargs) -> bool:
    try:
        return subprocess.run(cmd, check=False, **kwargs).returncode == 0
    except OSError:
        return False


def open_uri(uri: str) -> bool:
    if sys.platform == "darwin":
        cmd = ["open", uri]
    elif os.name == "nt":
        cmd = ["cmd", "/c", "start", "", uri]
    else:
        opener = shutil.which("xdg-open")
        if opener is None:
            return False
        cmd = [opener, uri]
    try:
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except OSError:
        return False


class Host(Protocol):
    def copy_files(self, paths: list[str]) -> bool: ...

    def copy_text(self, text: str) -> bool: ...

    def open_chat(self, phone: str) -> bool: ...

    def activate(self) -> bool: ...

    def clear_composer(self) -> bool: ...

    def paste(self) -> bool: ...

    def press_send(self) -> bool: ...


class BaseHost:
    def open_chat(self, phone: str) -> bool:
        return open_uri(desktop_chat_uri(phone))


def wait_for_open_chat(host: Host, sleep: Callable[[float], None]) -> None:
    sleep(CHAT_OPEN_SECONDS)
    host.activate()
    sleep(FOCUS_SECONDS)


def open_and_paste(
    host: Host,
    phone: str,
    settle: float,
    sleep: Callable[[float], None],
) -> str:
    """Returns an empty string on success, otherwise the failure code."""
    if not host.open_chat(phone):
        return "no-whatsapp"
    wait_for_open_chat(host, sleep)
    host.clear_composer()
    sleep(CLEAR_SECONDS)
    if not host.paste():
        return "failed"
    sleep(settle)
    return ""


def press_send_twice(host: Host, sleep: Callable[[float], None]) -> bool:
    """A stuck modifier turns Enter into a newline instead of a send. WhatsApp
    ignores Enter on an empty composer, so the second press only ever helps.
    """
    if not host.press_send():
        return False
    sleep(SEND_SECONDS)
    host.press_send()
    sleep(SEND_RETRY_SECONDS)
    return True


def share_text(
    host: Host,
    number: str,
    caption: str,
    send: bool = True,
    sleep: Callable[[float], None] = time.sleep,
) -> str:
    phone = digits_only(number)
    if not is_valid_number(phone):
        return "bad-number"
    text = caption.strip()
    if not text:
        return "no-text"
    if not host.copy_text(text):
        return "failed"
    failure = open_and_paste(host, phone, CAPTION_PASTE_SECONDS, sleep)
    if failure:
        return failure
    if not send:
        return "attached"
    return "sent" if press_send_twice(host, sleep) else "failed"


def share(
    host: Host,
    number: str,
    caption: str,
    files: list[str],
    send: bool = True,
    sleep: Callable[[float], None] = time.sleep,
    text_only: bool = False,
) -> str:
    if text_only:
        return share_text(host, number, caption, send=send, sleep=sleep)
    phone = digits_only(number)
    if not is_valid_number(phone):
        return "bad-number"
    paths = existing_files(files)
    if not paths:
        return "no-files"
    if not host.copy_files(paths):
        return "failed"
    failure = open_and_paste(host, phone, FILE_PASTE_SECONDS, sleep)
    if failure:
        return failure
    if caption.strip():
        if not host.copy_text(caption):
            return "failed"
        host.activate()
        sleep(FOCUS_SECONDS)
        if not host.paste():
            return "failed"
        sleep(CAPTION_PASTE_SECONDS)
    if not send:
        return "attached"
    return "sent" if press_send_twice(host, sleep) else "failed"


class MacHost(BaseHost):
    def copy_files(self, paths: list[str]) -> bool:
        return _mac_copy_files(paths)

    def copy_text(self, text: str) -> bool:
        return run_cmd(["pbcopy"], input=text.encode("utf-8"))

    def activate(self) -> bool:
        return run_cmd(
            ["open", "-a", "WhatsApp"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def clear_composer(self) -> bool:
        return _mac_hotkey(0, command=True) and _mac_hotkey(51)

    def paste(self) -> bool:
        return _mac_hotkey(9, command=True)

    def press_send(self) -> bool:
        # Plain Return. Any leaked Shift turns this into a newline.
        return _mac_hotkey(36)


class WindowsHost(BaseHost):
    def copy_files(self, paths: list[str]) -> bool:
        payload = bytearray(20)
        payload[0:4] = (20).to_bytes(4, "little")
        payload.extend(("\0".join(paths) + "\0\0").encode("utf-16-le"))
        return _win_clipboard(15, bytes(payload))

    def copy_text(self, text: str) -> bool:
        return _win_clipboard(13, (text + "\0").encode("utf-16-le"))

    def activate(self) -> bool:
        return _win_focus_whatsapp()

    def clear_composer(self) -> bool:
        return _win_hotkey("a", ctrl=True) and _win_hotkey("back")

    def paste(self) -> bool:
        return _win_hotkey("v", ctrl=True)

    def press_send(self) -> bool:
        return _win_hotkey("return")


class LinuxHost(BaseHost):
    def copy_files(self, paths: list[str]) -> bool:
        uris = "\n".join(f"file://{quote(path)}" for path in paths) + "\n"
        return _linux_clipboard(uris, "text/uri-list")

    def copy_text(self, text: str) -> bool:
        return _linux_clipboard(text, "text/plain")

    def activate(self) -> bool:
        if shutil.which("wmctrl") and run_cmd(["wmctrl", "-a", "WhatsApp"]):
            return True
        xdotool = shutil.which("xdotool")
        if not xdotool:
            return False
        found = subprocess.run(
            [xdotool, "search", "--name", "WhatsApp"],
            check=False,
            capture_output=True,
            text=True,
        )
        wids = found.stdout.strip().splitlines()
        return bool(wids) and run_cmd([xdotool, "windowactivate", "--sync", wids[-1]])

    def clear_composer(self) -> bool:
        return _linux_key("ctrl+a") and _linux_key("BackSpace")

    def paste(self) -> bool:
        return _linux_key("ctrl+v")

    def press_send(self) -> bool:
        return _linux_key("Return")


def host_for(platform: str | None = None) -> Host:
    name = platform or sys.platform
    if name == "darwin":
        return MacHost()
    if name.startswith("win"):
        return WindowsHost()
    return LinuxHost()


def _mac_copy_files(paths: list[str]) -> bool:
    try:
        objc = _ObjC()
        pasteboard = objc.msg(objc.cls("NSPasteboard"), "generalPasteboard")
        objc.msg(pasteboard, "clearContents", restype=ctypes.c_ulong)
        kind = objc.ns_string("NSFilenamesPboardType")
        objc.msg(
            pasteboard,
            "declareTypes:owner:",
            objc.ns_array([kind]),
            None,
            restype=ctypes.c_ulong,
            extra=(ctypes.c_void_p, ctypes.c_void_p),
        )
        return bool(
            objc.msg(
                pasteboard,
                "setPropertyList:forType:",
                objc.ns_array([objc.ns_string(path) for path in paths]),
                kind,
                restype=ctypes.c_bool,
                extra=(ctypes.c_void_p, ctypes.c_void_p),
            )
        )
    except OSError:
        return False


_CG_COMMAND_FLAG = 0x100000
_CG_SOURCE_PRIVATE_STATE = 1
_CG_SESSION_TAP = 0
_CG_CACHE: tuple | None = None


def _core_graphics():
    global _CG_CACHE
    if _CG_CACHE is not None:
        return _CG_CACHE
    cg = ctypes.cdll.LoadLibrary(
        "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics"
    )
    cg.CGEventSourceCreate.restype = ctypes.c_void_p
    cg.CGEventSourceCreate.argtypes = [ctypes.c_uint32]
    cg.CGEventCreateKeyboardEvent.restype = ctypes.c_void_p
    cg.CGEventCreateKeyboardEvent.argtypes = [
        ctypes.c_void_p,
        ctypes.c_uint16,
        ctypes.c_bool,
    ]
    cg.CGEventSetFlags.argtypes = [ctypes.c_void_p, ctypes.c_uint64]
    cg.CGEventPost.argtypes = [ctypes.c_uint32, ctypes.c_void_p]
    # A private source plus explicit flags keeps every event from inheriting
    # whatever modifier the user or an earlier hotkey left held down.
    _CG_CACHE = (cg, cg.CGEventSourceCreate(_CG_SOURCE_PRIVATE_STATE))
    return _CG_CACHE


def _mac_hotkey(key_code: int, command: bool = False) -> bool:
    try:
        cg, source = _core_graphics()
        flags = _CG_COMMAND_FLAG if command else 0
        for pressed in (True, False):
            event = cg.CGEventCreateKeyboardEvent(source, key_code, pressed)
            if not event:
                return False
            cg.CGEventSetFlags(event, flags)
            cg.CGEventPost(_CG_SESSION_TAP, event)
            time.sleep(KEY_GAP_SECONDS)
        return True
    except OSError:
        return False


class _ObjC:
    def __init__(self) -> None:
        lib = ctypes.util.find_library("objc")
        if not lib:
            raise OSError("objc runtime missing")
        ctypes.cdll.LoadLibrary(
            "/System/Library/Frameworks/Foundation.framework/Foundation"
        )
        ctypes.cdll.LoadLibrary("/System/Library/Frameworks/AppKit.framework/AppKit")
        self.objc = ctypes.cdll.LoadLibrary(lib)
        self.objc.objc_getClass.restype = ctypes.c_void_p
        self.objc.sel_registerName.restype = ctypes.c_void_p

    def cls(self, name: str):
        return self.objc.objc_getClass(name.encode())

    def sel(self, name: str):
        return self.objc.sel_registerName(name.encode())

    def msg(self, receiver, selector: str, *args, restype=None, extra=()):
        restype = ctypes.c_void_p if restype is None else restype
        extra_types = extra or tuple(ctypes.c_void_p for _ in args)
        func = ctypes.CFUNCTYPE(
            restype,
            ctypes.c_void_p,
            ctypes.c_void_p,
            *extra_types,
        )(("objc_msgSend", self.objc))
        return func(receiver, self.sel(selector), *args)

    def ns_string(self, text: str):
        return self.msg(
            self.cls("NSString"),
            "stringWithUTF8String:",
            text.encode(),
            extra=(ctypes.c_char_p,),
        )

    def ns_array(self, items: list):
        arr = self.msg(self.cls("NSMutableArray"), "array")
        for item in items:
            self.msg(arr, "addObject:", item, extra=(ctypes.c_void_p,))
        return arr


def _win_clipboard(fmt: int, data: bytes) -> bool:
    try:
        kernel32 = ctypes.windll.kernel32
        user32 = ctypes.windll.user32
        alloc = kernel32.GlobalAlloc(0x0002, len(data))
        if not alloc:
            return False
        locked = kernel32.GlobalLock(alloc)
        ctypes.memmove(locked, data, len(data))
        kernel32.GlobalUnlock(alloc)
        if not user32.OpenClipboard(None):
            return False
        try:
            user32.EmptyClipboard()
            return bool(user32.SetClipboardData(fmt, alloc))
        finally:
            user32.CloseClipboard()
    except Exception:
        return False


def _win_focus_whatsapp() -> bool:
    try:
        from ctypes import wintypes

        found: list[int] = []

        @ctypes.WINFUNCTYPE(ctypes.c_bool, wintypes.HWND, wintypes.LPARAM)
        def each(hwnd, _lp):
            length = ctypes.windll.user32.GetWindowTextLengthW(hwnd)
            buf = ctypes.create_unicode_buffer(length + 1)
            ctypes.windll.user32.GetWindowTextW(hwnd, buf, length + 1)
            if "WhatsApp" in buf.value:
                found.append(hwnd)
            return True

        ctypes.windll.user32.EnumWindows(each, 0)
        if not found:
            return False
        ctypes.windll.user32.ShowWindow(found[0], 9)
        return bool(ctypes.windll.user32.SetForegroundWindow(found[0]))
    except Exception:
        return False


def _win_hotkey(key: str, ctrl: bool = False) -> bool:
    try:
        codes = {"a": 0x41, "v": 0x56, "return": 0x0D, "back": 0x08}
        vk = codes[key]
        events = ([(0x11, 0)] if ctrl else []) + [(vk, 0), (vk, 2)]
        if ctrl:
            events.append((0x11, 2))
        for code, flags in events:
            ctypes.windll.user32.keybd_event(code, 0, flags, 0)
        return True
    except Exception:
        return False


def _linux_clipboard(text: str, mime: str) -> bool:
    payload = text.encode("utf-8")
    wl = shutil.which("wl-copy")
    if wl and run_cmd([wl, "-t", mime], input=payload):
        return True
    xclip = shutil.which("xclip")
    if xclip:
        return run_cmd(
            [xclip, "-selection", "clipboard", "-t", mime],
            input=payload,
        )
    xsel = shutil.which("xsel")
    return bool(
        xsel
        and mime.startswith("text/plain")
        and run_cmd([xsel, "--clipboard", "--input"], input=payload)
    )


def _linux_key(combo: str) -> bool:
    xdotool = shutil.which("xdotool")
    if xdotool:
        return run_cmd([xdotool, "key", combo])
    ydotool = shutil.which("ydotool")
    if not ydotool:
        return False
    keys = {
        "ctrl+v": ["29:1", "47:1", "47:0", "29:0"],
        "ctrl+a": ["29:1", "30:1", "30:0", "29:0"],
        "BackSpace": ["14:1", "14:0"],
        "Return": ["28:1", "28:0"],
    }.get(combo)
    return bool(keys) and run_cmd([ydotool, "key", *keys])


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Send a Fluship PDF and APKs on WhatsApp Desktop.",
    )
    parser.add_argument("--number", required=True)
    parser.add_argument("--caption", default="")
    parser.add_argument("--caption-file", default="")
    parser.add_argument("--text", default="")
    parser.add_argument("--text-only", action="store_true")
    parser.add_argument("--file", action="append", default=[])
    parser.add_argument("--no-send", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args(argv)


def caption_from(args: argparse.Namespace) -> str:
    if args.text:
        return args.text
    if args.caption_file:
        return Path(args.caption_file).read_text(encoding="utf-8")
    return args.caption


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    caption = caption_from(args)
    files = existing_files(args.file)
    text_only = args.text_only or (bool(args.text) and not files)
    if args.dry_run:
        print(f"WhatsApp number: {digits_only(args.number)}")
        print(f"Chat URI: {desktop_chat_uri(args.number)}")
        if text_only:
            print("Text only")
            print(f"Caption: {caption}")
            print("WhatsApp result: dry-run")
            return 0 if caption.strip() else 2
        print("Attachments:")
        for path in files:
            print(f"  {path}")
        print("WhatsApp result: dry-run")
        return 0 if files else 2
    result = share(
        host=host_for(),
        number=args.number,
        caption=caption,
        files=files,
        send=not args.no_send,
        text_only=text_only,
    )
    print(f"WhatsApp result: {result}")
    if result in {"sent", "attached"}:
        return 0
    if result == "bad-number":
        return 64
    return 2


if __name__ == "__main__":
    sys.exit(main())
