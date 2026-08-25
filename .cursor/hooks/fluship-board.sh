#!/bin/sh
# Cursor hook shim. The Dart program reads the event JSON on stdin.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
exec dart "$root/tool/pipeline_board_hook.dart" "$1"
