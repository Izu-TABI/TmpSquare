#!/usr/bin/env bash
# DropShelf.app をビルドする
#
# 使い方:
#   ./scripts/build.sh            build/DropShelf.app を作る
#   ./scripts/build.sh --run      ビルドして起動する
#   ./scripts/build.sh --install  /Applications にインストールして起動する
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="DropShelf"
APP="build/$APP_NAME.app"

INSTALL=false
RUN=false
for arg in "$@"; do
  case "$arg" in
    --install) INSTALL=true; RUN=true ;;
    --run) RUN=true ;;
    *) echo "不明なオプション: $arg" >&2; exit 1 ;;
  esac
done

if [[ ! -f Resources/AppIcon.icns ]]; then
  echo "▸ アイコンを生成"
  swift scripts/make-icon.swift Resources/AppIcon.icns
fi

echo "▸ コンパイル (release)"
swift build -c release
BIN_DIR="$(swift build -c release --show-bin-path)"

echo "▸ $APP を組み立て"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "▸ 署名 (ad-hoc)"
codesign --force --sign - "$APP"

if $RUN; then
  pkill -x "$APP_NAME" 2>/dev/null && sleep 0.5 || true
fi

if $INSTALL; then
  echo "▸ /Applications にインストール"
  rm -rf "/Applications/$APP_NAME.app"
  cp -R "$APP" /Applications/
  APP="/Applications/$APP_NAME.app"
fi

if $RUN; then
  open "$APP"
fi

echo "✓ $APP"
