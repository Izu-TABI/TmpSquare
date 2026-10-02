import Foundation

/// 画面に出す文字の英語訳。日本語の文をそのまま鍵にする
///
/// ファイルのサイズや種類などシステムが出す文字と揃うよう、アプリが選んだ言語
/// （Mac の言語設定で日本語が英語より上にあれば日本語、それ以外は英語）に合わせる。
enum Localization {
    static let usesJapanese: Bool = Bundle.main.preferredLocalizations.first?.hasPrefix("ja") ?? false

    static func text(_ japanese: String) -> String {
        usesJapanese ? japanese : (english[japanese] ?? japanese)
    }

    static let english: [String: String] = [
        // メニューバー
        "新しいシェルフ": "New Shelf",
        "すべてのシェルフを閉じる": "Close All Shelves",
        "ドラッグ中のシェイクで開く": "Open by Shaking While Dragging",
        "シェイクの感度": "Shake Sensitivity",
        "弱い": "Low",
        "標準": "Medium",
        "強い": "High",
        "ドラッグアウトした項目をシェルフから外す": "Remove Items After Dragging Them Out",
        "ログイン時に起動": "Open at Login",
        "使い方": "How to Use",
        "TmpSquare について": "About TmpSquare",
        "TmpSquare を終了": "Quit TmpSquare",
        "振れば出てくる、ファイルの一時置き場。": "Shake to open a temporary spot for your files.",

        // シェルフ
        "シェルフ": "Shelf",
        "ここにドロップ": "Drop Here",
        "ドロップして追加": "Drop to Add",
        "シェルフを閉じる（esc）": "Close Shelf (esc)",
        "重ねて表示": "Show as Stack",
        "一覧で表示": "Show as List",
        "アクション": "Actions",
        "開く": "Open",
        "Finder で表示": "Show in Finder",
        "コピー": "Copy",
        "パスをコピー": "Copy Path",
        "ZIP に圧縮": "Compress to ZIP",
        "シェルフから外す": "Remove from Shelf",
        "画像": "Image",
        "アーカイブ": "Archive",

        // 初回の案内
        "TmpSquare の使い方": "How to Use TmpSquare",
        "振ってシェルフを出す": "Shake to open a shelf",
        "ファイルをドラッグしながら、カーソルを左右に振ります。⌥⇧Space やメニューバーの ":
            "While dragging files, shake the cursor left and right. You can also press ⌥⇧Space or click ",
        " からも開けます。": " in the menu bar.",
        "ひとまず置いておく": "Park your files",
        "シェルフにドロップしてから、移動先のフォルダやアプリを開きます。ほかのファイルも続けて追加できます。":
            "Drop them on the shelf, then open the destination folder or app. You can keep adding more files.",
        "まとめて取り出す": "Drag them all out",
        "重なったカードをドラッグすると全部まとめて取り出せます。クリックすると一覧になり、1 つずつ取り出せます。":
            "Drag the card stack to take everything out at once. Click it to see a list and drag items one by one.",
        "右クリックでもっと": "More with a right-click",
        "開く・Finder で表示・共有・コピー・ZIP に圧縮などができます。":
            "Open, show in Finder, share, copy, compress to ZIP, and more.",
        "ログイン時に起動する": "Open at Login",
        "シェルフを開いてみる": "Try Opening a Shelf",
        "この案内は、メニューバーのアイコンの「使い方」からいつでも開けます。":
            "You can open this guide anytime from “How to Use” in the menu bar icon.",
    ]

    /// 「4 項目」/「4 items」
    static func itemCount(_ count: Int) -> String {
        usesJapanese ? "\(count) 項目" : (count == 1 ? "1 item" : "\(count) items")
    }

    /// 「ほか 3 項目」/「and 3 more」
    static func andMore(_ count: Int) -> String {
        usesJapanese ? "ほか \(count) 項目" : "and \(count) more"
    }

    /// 「テキスト・12 文字」/「Text · 12 characters」
    static func textDetail(characters count: Int) -> String {
        usesJapanese ? "テキスト・\(count) 文字" : "Text · \(count) \(count == 1 ? "character" : "characters")"
    }

    /// メニュー項目の後ろに付ける「（4 項目）」/「 (4 Items)」
    static func countSuffix(_ count: Int) -> String {
        usesJapanese ? "（\(count) 項目）" : " (\(count) Items)"
    }

    static func zipFailed(status: Int32) -> String {
        usesJapanese
            ? "ZIP の作成に失敗しました（ditto 終了コード \(status)）"
            : "Couldn’t create the ZIP file (ditto exit code \(status))"
    }
}

/// 画面に出す文字（英語の環境では英語にする）
func L(_ japanese: String) -> String {
    Localization.text(japanese)
}
