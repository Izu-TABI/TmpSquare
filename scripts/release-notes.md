## インストール

1. 下の **TmpSquare.zip** をダウンロードして開き、`TmpSquare.app` を「アプリケーション」フォルダに移動します。
2. `TmpSquare.app` を開きます。Apple の公証を受けていないため、初回は「開いていません」という警告が出るので「完了」を押します。
3. 「システム設定」→「プライバシーとセキュリティ」を開き、下の方にある TmpSquare の「このまま開く」を押します。
4. もう一度確認が出たら「このまま開く」を押します。

メニューバーに点線の四角のアイコンが出たら準備完了です。ファイルをドラッグしながらカーソルを左右に振るとシェルフが開きます（⌥⇧Space でも開けます）。

ターミナルが使える場合は、手順 2〜4 の代わりに次のコマンドでも開けるようになります。

```
xattr -dr com.apple.quarantine /Applications/TmpSquare.app
```

**動作環境**: macOS 14 以降（Apple シリコン / Intel）

---

## Installation

1. Download **TmpSquare.zip** below, open it, and move `TmpSquare.app` to your Applications folder.
2. Open `TmpSquare.app`. The app isn't notarized by Apple, so the first time you'll see a warning that it was not opened. Click **Done**.
3. Open **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** next to TmpSquare.
4. Confirm with **Open Anyway** again.

You're all set when a dashed-square icon appears in the menu bar. Shake the cursor left and right while dragging files to open a shelf (or press ⌥⇧Space). The app's interface is currently in Japanese only.

If you're comfortable with Terminal, you can run this instead of steps 2–4:

```
xattr -dr com.apple.quarantine /Applications/TmpSquare.app
```

**Requirements**: macOS 14 or later (Apple silicon / Intel)
