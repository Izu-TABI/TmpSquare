#!/usr/bin/env bash
# README の画像（docs/images）を作り直す
#
# アプリのシェルフを実際に動かしてコマ撮りし、カーソルやドラッグ中のファイルを描き足して、
# 日本語版と英語版の動作イメージ（demo.gif / demo-en.gif）とスクリーンショット、
# SNS などで共有したときに出る画像（social-preview.png）、アイコンの画像を作る。
# 撮影中は画面中央にシェルフが少しの間表示される。画面全体は撮らないので、ほかのアプリは写らない。
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK:?}"' EXIT
[[ -n "${KEEP_WORK:-}" ]] && trap - EXIT && echo "作業フォルダ: $WORK"

mkdir -p docs/images

echo "▸ アイコンの画像を書き出し"
swift scripts/make-icon.swift --preview "$WORK/icon.png" > /dev/null
sips -Z 256 "$WORK/icon.png" --out docs/images/icon.png > /dev/null
echo "✓ docs/images/icon.png"

echo "▸ サンプルファイルを作成"
swift scripts/make-demo.swift samples "$WORK/samples"

echo "▸ アプリをビルド"
swift build
# 実際のアプリと同じ表示（ファイル種別やサイズの表記）にするため、Info.plist 付きのバンドルに入れて起動する
APP="$WORK/TmpSquare.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/debug/TmpSquare "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
# 起動時に一時フォルダを掃除するので、使用中の TmpSquare と別の識別子にして影響しないようにする
/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier com.odentabetai.TmpSquare.demo' "$APP/Contents/Info.plist"

for LANGUAGE in ja en; do
  SUFFIX=""
  [[ "$LANGUAGE" == "en" ]] && SUFFIX="-en"

  echo "▸ シェルフをコマ撮り ($LANGUAGE)"
  "$APP/Contents/MacOS/TmpSquare" --open-shelf --dark --record "$WORK/frames-$LANGUAGE" \
    "$WORK/samples/Photo.png" "$WORK/samples/Report.pdf" "$WORK/samples/Notes.txt" "$WORK/samples/Assets" \
    -AppleLanguages "($LANGUAGE)"

  echo "▸ 動作イメージを合成 ($LANGUAGE)"
  swift scripts/make-demo.swift compose "$WORK/frames-$LANGUAGE" "$WORK/samples" docs/images "$SUFFIX"
done

echo "▸ 共有用の画像を合成"
swift scripts/make-demo.swift social "$WORK/frames-ja" "$WORK/samples" docs/images/icon.png docs/images/social-preview.png
