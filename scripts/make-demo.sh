#!/usr/bin/env bash
# README の動作イメージ（docs/images）を作り直す
#
# アプリのシェルフを実際に動かしてコマ撮りし、カーソルやドラッグ中のファイルを描き足して
# demo.gif と screenshots.png にする。アイコンの画像も書き出す。
# 撮影中は画面中央にシェルフが少しの間表示される。
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK:?}"' EXIT
[[ -n "${KEEP_WORK:-}" ]] && trap - EXIT && echo "作業フォルダ: $WORK"

echo "▸ サンプルファイルを作成"
swift scripts/make-demo.swift samples "$WORK/samples"

echo "▸ シェルフをコマ撮り"
swift build
# 実際のアプリと同じ表示（日本語のファイル種別やサイズ）にするため、Info.plist 付きのバンドルに入れて起動する
APP="$WORK/TmpSquare.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/debug/TmpSquare "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
# 起動時に一時フォルダを掃除するので、使用中の TmpSquare と別の識別子にして影響しないようにする
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.odentabetai.TmpSquare.demo' "$APP/Contents/Info.plist"
"$APP/Contents/MacOS/TmpSquare" --open-shelf --dark --record "$WORK/frames" \
  "$WORK/samples/Photo.png" "$WORK/samples/Report.pdf" "$WORK/samples/Notes.txt" "$WORK/samples/Assets"

echo "▸ 動作イメージを合成"
swift scripts/make-demo.swift compose "$WORK/frames" "$WORK/samples" docs/images

echo "▸ アイコンの画像を書き出し"
swift scripts/make-icon.swift --preview "$WORK/icon.png"
sips -Z 256 "$WORK/icon.png" --out docs/images/icon.png > /dev/null
echo "✓ docs/images/icon.png"
