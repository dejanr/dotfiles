#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
EXTENSION_NAME=pi-sd4-provider.ts
PI_AGENT_DIR=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
EXTENSION_DIR="$PI_AGENT_DIR/extensions"
DS4_DIR="$HOME/.pi/ds4"
SUPPORT_LINK="$DS4_DIR/support"

if [ ! -f "$ROOT/$EXTENSION_NAME" ]; then
    echo "error: $ROOT/$EXTENSION_NAME not found" >&2
    exit 1
fi

mkdir -p "$EXTENSION_DIR" "$DS4_DIR"
ln -sfn "$ROOT/$EXTENSION_NAME" "$EXTENSION_DIR/$EXTENSION_NAME"

echo "Installed pi extension symlink:"
echo "  $EXTENSION_DIR/$EXTENSION_NAME -> $ROOT/$EXTENSION_NAME"

if [ ! -e "$SUPPORT_LINK" ]; then
    ln -s "$ROOT" "$SUPPORT_LINK"
    echo "Installed ds4 runtime symlink:"
    echo "  $SUPPORT_LINK -> $ROOT"
elif [ -L "$SUPPORT_LINK" ] && [ "$(readlink "$SUPPORT_LINK")" = "$ROOT" ]; then
    echo "ds4 runtime symlink already points at this checkout:"
    echo "  $SUPPORT_LINK -> $ROOT"
else
    echo "Leaving existing ds4 runtime in place:"
    echo "  $SUPPORT_LINK"
    echo "To test against this checkout, move that path aside or run with:"
    echo "  DS4_RUNTIME_DIR=$ROOT pi"
fi

echo
echo "Reload pi with /reload or start pi normally; the extension is auto-discovered."
