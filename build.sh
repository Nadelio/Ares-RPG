#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="${1:-./dist}"
GAME_NAME="${2:-AresRPG}"

_uname="$(uname -s)"
if [[ -n "${WINDIR:-}${COMSPEC:-}" ]] || \
   [[ "${OS:-}" == "Windows_NT" ]] || \
   { [[ "$_uname" == "Linux" ]] && grep -qi "microsoft\|wsl" /proc/version 2>/dev/null; } || \
   [[ "$_uname" == MINGW* ]] || [[ "$_uname" == MSYS* ]] || [[ "$_uname" == CYGWIN* ]]; then
    PLATFORM="windows"
elif [[ "$_uname" == "Darwin" ]]; then
    PLATFORM="macos"
else
    PLATFORM="linux"
fi

if [[ -z "${LOVE_PATH:-}" ]]; then
    case "$PLATFORM" in
        windows)
            if [[ "${WINDIR:-}" == /mnt/* ]] || [[ -d /mnt/c ]]; then
                LOVE_PATH="/mnt/c/Program Files/LOVE"
            else
                LOVE_PATH="/c/Program Files/LOVE"
            fi ;;
        macos)  LOVE_PATH="/Applications/love.app" ;;
        linux)  LOVE_PATH="$(which love 2>/dev/null || echo '/usr/bin/love')" ;;
    esac
fi

case "$PLATFORM" in
    windows)
        [[ -f "$LOVE_PATH/love.exe" ]] || {
            echo "Error: love.exe not found in '$LOVE_PATH'" >&2; exit 1
        } ;;
    macos)
        [[ -d "$LOVE_PATH" ]] || {
            echo "Error: love.app not found at '$LOVE_PATH'" >&2; exit 1
        } ;;
    linux)
        [[ -f "$LOVE_PATH" ]] || {
            echo "Error: love binary not found at '$LOVE_PATH'" >&2; exit 1
        } ;;
esac

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

LOVE_FILE="$OUTPUT_DIR/game.love"

echo "Compressing game files..."
zip -r "$LOVE_FILE" main.lua core assets

case "$PLATFORM" in
    windows)
        echo "Building Windows executable..."
        cat "$LOVE_PATH/love.exe" "$LOVE_FILE" > "$OUTPUT_DIR/$GAME_NAME.exe"
        cp "$LOVE_PATH"/*.dll "$OUTPUT_DIR/"
        echo "  $OUTPUT_DIR/$GAME_NAME.exe"
        ;;
    macos)
        echo "Building MacOS app bundle..."
        cp -r "$LOVE_PATH" "$OUTPUT_DIR/$GAME_NAME.app"
        cp "$LOVE_FILE" "$OUTPUT_DIR/$GAME_NAME.app/Contents/Resources/"
        echo "  $OUTPUT_DIR/$GAME_NAME.app"
        ;;
    linux)
        echo "Building Linux executable..."
        cat "$LOVE_PATH" "$LOVE_FILE" > "$OUTPUT_DIR/$GAME_NAME"
        chmod +x "$OUTPUT_DIR/$GAME_NAME"
        echo "  $OUTPUT_DIR/$GAME_NAME  (requires Love2D shared libs on target)"
        ;;
esac

rm "$LOVE_FILE"

cat > "$OUTPUT_DIR/README.txt" << 'EOF'
Thank you so much for playing or modding my game! I hope you enjoy it!

If you have an bugs or suggestions, please create an issue on Github: https://github.com/Nadelio/Ares-RPG/issues
If you want me to list your mod under the Ares Mod Index, please create an issue on Github: https://github.com/Nadelio/Ares-Mod-Index/issues

To install mods, place them in your OS's executable data directory:
  Windows: %APPDATA%\AresRPG\mods\
  MacOS:   ~/Library/Application Support/AresRPG/mods/
  Linux:   ~/.local/share/AresRPG/mods/

Each mod is a subfolder containing a mod.lua manifest:
mods/
  my_mod/
    mod.lua
    systems/
    components/
    prefabs/

If you need help with modding, please read the documentation: https://github.com/Nadelio/Ares-RPG/tree/main/docs
If you have a question that isn't answered by the docs or by the modding FAQ, please create an issue on Github: https://github.com/Nadelio/Ares-RPG/issues
EOF

mkdir -p "$OUTPUT_DIR/saves"
touch "$OUTPUT_DIR/saves/demo.log"

echo ""
echo "Build complete -> $OUTPUT_DIR/"