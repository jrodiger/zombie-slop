#!/bin/sh
set -eu
SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ZOMBIE_HOME=${ZOMBIE_HOME:-"$HOME/Documents/ZombieSlop"}
GODOT=${GODOT:-"$ZOMBIE_HOME/tools/Godot.app/Contents/MacOS/Godot"}
if [ "${1:-macOS}" = Android ]; then
 exec python3 "$SOURCE_DIR/scripts/build_android.py" --home "$ZOMBIE_HOME" --godot "$GODOT"
fi
python3 "$SOURCE_DIR/scripts/check_source.py"
python3 "$SOURCE_DIR/scripts/assemble.py" --home "$ZOMBIE_HOME" --assets "${ZOMBIE_ASSETS:-$SOURCE_DIR/../zombie-slop-assets}"
"$GODOT" --headless --path "$ZOMBIE_HOME/workspace" --editor --import
"$GODOT" --headless --path "$ZOMBIE_HOME/workspace" --export-release "${1:-macOS}"
python3 "$SOURCE_DIR/scripts/record_build.py" --home "$ZOMBIE_HOME" --platform "${1:-macOS}"
