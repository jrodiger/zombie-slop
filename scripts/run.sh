#!/bin/sh
set -eu
SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ZOMBIE_HOME=${ZOMBIE_HOME:-"$HOME/Documents/ZombieSlop"}
GODOT=${GODOT:-"$ZOMBIE_HOME/tools/Godot.app/Contents/MacOS/Godot"}
python3 "$SOURCE_DIR/scripts/assemble.py" --home "$ZOMBIE_HOME"
exec "$GODOT" --path "$ZOMBIE_HOME/workspace" "$@"
