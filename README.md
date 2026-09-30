# DropShelf

Dropover のような、ファイルを一時的に置いておける「シェルフ」を出す macOS のメニューバーアプリです。

## 必要なもの

- macOS 14 以降（macOS 26 では Liquid Glass で表示）
- Xcode の Command Line Tools（Xcode 本体は不要）

## ビルドと起動

```bash
./scripts/build.sh --run       # build/DropShelf.app を作って起動
./scripts/build.sh --install   # /Applications にインストールして起動
./scripts/test.sh              # テストを実行
```

## 使い方

| 操作 | 動作 |
| --- | --- |
| ファイルをドラッグ中にカーソルを左右にシェイク | 振った範囲の中心にシェルフが開き、手が止まるまでカーソルの下についてくる（そのままドロップできる） |
| ⌥⇧Space / メニューバーの「新しいシェルフ」 | 空のシェルフを開く |
| シェルフにドロップ | ファイル・フォルダ・画像・リンク・テキスト・写真アプリや Mail の添付を追加 |
| 重なったカードをドラッグ | 全項目をまとめて取り出す |
| カードをクリック / 一覧ボタン | 一覧表示にする（1 項目ずつドラッグ、ダブルクリックで開く） |
| 右クリック / 「…」ボタン | 開く・Finder で表示・共有・コピー・パスをコピー・ZIP に圧縮・シェルフから外す |
| ヘッダーをドラッグ | シェルフを移動 |
| ✕ / esc | シェルフを閉じる |

- 取り出し先が Finder の場合は Finder と同じ動作になります（同じディスクなら移動、⌥ を押しながらでコピー）。
- 取り出した項目はシェルフから外れ、空になったシェルフは自動で閉じます（メニューで変更できます）。
- ドロップされた画像データ・添付ファイル・ZIP は `~/Library/Caches/com.odentabetai.DropShelf/Items` に保存され、次回起動時に削除されます。
- シェイクの有効／無効と感度、ログイン時の起動はメニューバーから設定できます。

## 構成

```
Sources/DropShelf/
├── App/        起動処理、メニューバー、設定、グローバルホットキー
├── Shake/      ドラッグ中のシェイク検出
├── Shelf/      シェルフのウィンドウ・状態・ドロップの取り込み・アクション
├── Views/      SwiftUI の見た目と、AppKit で処理するドラッグアウト
└── Support/    一時領域、ZIP 作成、メニュー項目のヘルパー
Tests/DropShelfTests/   シェイク判定・シェルフの位置・取り込み・ドロップ受付・ZIP のテスト
scripts/        ビルド、テスト、アイコン生成
```

## 開発用オプション（デバッグビルドのみ）

```bash
swift build
.build/debug/DropShelf --open-shelf --expanded ~/Desktop/a.pdf ~/Desktop/b.png
```

`--open-shelf` で項目入りのシェルフを画面中央に開きます。画面収録の権限がなくても、自分のウィンドウを PNG に書き出して UI を確認できます。

| オプション | 内容 |
| --- | --- |
| `--snapshot out.png` | シェルフの見た目を書き出す |
| `--filmstrip out.png` | 重ね表示⇄一覧表示を切り替え、その間のコマを並べて書き出す |
| `--drop-later` | 空のシェルフで開き、`--filmstrip` のときに項目を追加する（ドロップ時の動き） |
| `--expanded` | 一覧表示で開く |
| `--dark` / `--light` | 外観を固定する |
| `--key` / `--shadow` | キーウィンドウにしてから撮る／ウィンドウの影も含めて撮る |

アニメーションの速さは `Sources/DropShelf/Views/ShelfView.swift` の `ShelfMotion` にまとめています。

## ライセンス

[MIT License](LICENSE)
