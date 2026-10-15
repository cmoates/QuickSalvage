#!/usr/bin/env bash
# Build a Vortex-compatible UE4SS Lua mod zip.
# Layout: QuickSalvage/Scripts/*.lua (+ LICENSE, README, enabled.txt, Info.json)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOD_NAME="QuickSalvage"
VERSION="${VERSION:-dev}"
STAGE="$ROOT/dist/$MOD_NAME"
OUT_ZIP="$ROOT/dist/${MOD_NAME}-${VERSION}.zip"

rm -rf "$ROOT/dist"
mkdir -p "$STAGE/Scripts"

cp "$ROOT/Scripts/"*.lua "$STAGE/Scripts/"
cp "$ROOT/LICENSE" "$ROOT/README.md" "$STAGE/"
cp "$ROOT/enabled.txt" "$STAGE/"
sed "s/__VERSION__/${VERSION}/g" "$ROOT/Info.json" > "$STAGE/Info.json"

(
  cd "$ROOT/dist"
  zip -r "$(basename "$OUT_ZIP")" "$MOD_NAME"
)

echo "Built $OUT_ZIP"
echo "package_path=$OUT_ZIP"
