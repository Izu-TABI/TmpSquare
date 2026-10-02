#!/usr/bin/env bash
# Homebrew の tap（Izu-TABI/homebrew-tap）の tmpsquare を、公開したリリースに合わせて更新する
#
# 使い方: ./scripts/update-tap.sh
# release.sh の最後でも実行される。build/TmpSquare.zip（公開したもの）のハッシュ値で cask を書いて push する
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
ZIP="build/TmpSquare.zip"
if [[ ! -f "$ZIP" ]]; then
  echo "$ZIP がありません。先に ./scripts/release.sh を実行してください。" >&2
  exit 1
fi
SHA="$(shasum -a 256 "$ZIP" | cut -d' ' -f1)"

TAP="build/homebrew-tap"
if [[ -d "$TAP/.git" ]]; then
  git -C "$TAP" pull --quiet
else
  gh repo clone Izu-TABI/homebrew-tap "$TAP" -- --quiet
fi
# 個人のアカウントで push できるよう、この clone だけ gh の認証を使う
git -C "$TAP" config credential.https://github.com.helper ""
git -C "$TAP" config --add credential.https://github.com.helper '!gh auth git-credential'

mkdir -p "$TAP/Casks"
cat > "$TAP/Casks/tmpsquare.rb" <<EOF
cask "tmpsquare" do
  version "$VERSION"
  sha256 "$SHA"

  url "https://github.com/Izu-TABI/TmpSquare/releases/download/v#{version}/TmpSquare.zip"
  name "TmpSquare"
  desc "Temporary file shelf that appears when you shake the cursor while dragging"
  homepage "https://github.com/Izu-TABI/TmpSquare"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :sonoma

  app "TmpSquare.app"

  zap trash: [
    "~/Library/Caches/com.odentabetai.TmpSquare",
    "~/Library/Preferences/com.odentabetai.TmpSquare.plist",
  ]

  caveats <<~EOS
    TmpSquare is not notarized by Apple, so macOS blocks it on first launch.
    Open System Settings > Privacy & Security and click "Open Anyway".
  EOS
end
EOF

git -C "$TAP" add Casks/tmpsquare.rb
if git -C "$TAP" diff --cached --quiet; then
  echo "tap の tmpsquare はすでに $VERSION です"
  exit 0
fi
git -C "$TAP" commit --quiet -m "tmpsquare $VERSION"
git -C "$TAP" push --quiet
echo "✓ Homebrew の tap を $VERSION に更新しました"
