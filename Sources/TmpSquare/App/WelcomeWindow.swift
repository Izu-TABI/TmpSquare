import AppKit

/// 初回起動時と「使い方」で出す案内
///
/// メニューバーだけのアプリは起動しても何も見えないので、何をすればいいかをここで伝える。
@MainActor
final class WelcomeWindowController: NSObject {
    var onOpenShelf: (() -> Void)?
    private(set) var window: NSWindow?
    private var loginCheckbox: NSButton?

    private static let shownKey = "HasShownWelcome"

    /// 初めての起動なら案内を出す
    func showIfFirstLaunch() {
        guard !UserDefaults.standard.bool(forKey: Self.shownKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.shownKey)
        show()
    }

    func show() {
        let window = window ?? makeWindow()
        self.window = window
        loginCheckbox?.state = LoginItem.isEnabled ? .on : .off
        NSApp.activate()
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    @objc private func openShelfTapped() {
        window?.orderOut(nil)
        onOpenShelf?()
    }

    @objc private func loginToggled(_ sender: NSButton) {
        LoginItem.setEnabled(sender.state == .on)
        sender.state = LoginItem.isEnabled ? .on : .off
    }

    private func makeWindow() -> NSWindow {
        let width: CGFloat = 440
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: 560),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = L("TmpSquare の使い方")
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isReleasedWhenClosed = false

        let icon = NSImageView(image: NSApp.applicationIconImage)
        icon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 84),
            icon.heightAnchor.constraint(equalToConstant: 84),
        ])
        let title = Self.label("TmpSquare", font: .systemFont(ofSize: 24, weight: .bold))
        let subtitle = Self.label(L("振れば出てくる、ファイルの一時置き場。"), font: .systemFont(ofSize: 13), color: .secondaryLabelColor)

        let bodyWidth = width - 64 - 44
        let steps = NSStackView(views: [
            Self.step(symbol: "cursorarrow.motionlines", title: L("振ってシェルフを出す"), body: Self.shakeText(), width: bodyWidth),
            Self.step(
                symbol: "tray.and.arrow.down", title: L("ひとまず置いておく"),
                body: NSAttributedString(string: L("シェルフにドロップしてから、移動先のフォルダやアプリを開きます。ほかのファイルも続けて追加できます。")),
                width: bodyWidth
            ),
            Self.step(
                symbol: "square.stack.3d.up", title: L("まとめて取り出す"),
                body: NSAttributedString(string: L("重なったカードをドラッグすると全部まとめて取り出せます。クリックすると一覧になり、1 つずつ取り出せます。")),
                width: bodyWidth
            ),
            Self.step(
                symbol: "ellipsis.circle", title: L("右クリックでもっと"),
                body: NSAttributedString(string: L("開く・Finder で表示・共有・コピー・ZIP に圧縮などができます。")),
                width: bodyWidth
            ),
        ])
        steps.orientation = .vertical
        steps.alignment = .leading
        steps.spacing = 16

        let checkbox = NSButton(checkboxWithTitle: L("ログイン時に起動する"), target: self, action: #selector(loginToggled(_:)))
        checkbox.state = LoginItem.isEnabled ? .on : .off
        loginCheckbox = checkbox

        let openShelf = NSButton(title: L("シェルフを開いてみる"), target: self, action: #selector(openShelfTapped))
        openShelf.bezelStyle = .push
        openShelf.controlSize = .large
        openShelf.keyEquivalent = "\r"
        openShelf.translatesAutoresizingMaskIntoConstraints = false
        openShelf.widthAnchor.constraint(greaterThanOrEqualToConstant: 200).isActive = true

        let footer = Self.label(
            L("この案内は、メニューバーのアイコンの「使い方」からいつでも開けます。"),
            font: .systemFont(ofSize: 11), color: .tertiaryLabelColor
        )

        let stack = NSStackView(views: [icon, title, subtitle, steps, checkbox, openShelf, footer])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 6
        stack.setCustomSpacing(10, after: icon)
        stack.setCustomSpacing(22, after: subtitle)
        stack.setCustomSpacing(22, after: steps)
        stack.setCustomSpacing(14, after: checkbox)
        stack.setCustomSpacing(12, after: openShelf)
        stack.edgeInsets = NSEdgeInsets(top: 40, left: 32, bottom: 22, right: 32)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            content.widthAnchor.constraint(equalToConstant: width),
        ])
        window.contentView = content
        window.setContentSize(content.fittingSize)
        return window
    }

    /// 「…⌥⇧Space やメニューバーの [アイコン] からも開けます。」（アイコンは文字の中に入れる）
    private static func shakeText() -> NSAttributedString {
        let text = NSMutableAttributedString(string: L("ファイルをドラッグしながら、カーソルを左右に振ります。⌥⇧Space やメニューバーの "))
        let attachment = NSTextAttachment()
        attachment.image = tinted(StatusIcon.make(), color: .secondaryLabelColor)
        attachment.bounds = CGRect(x: 0, y: -3, width: 15, height: 15)
        text.append(NSAttributedString(attachment: attachment))
        text.append(NSAttributedString(string: L(" からも開けます。")))
        return text
    }

    private static func tinted(_ image: NSImage, color: NSColor) -> NSImage {
        NSImage(size: image.size, flipped: false) { rect in
            image.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }

    private static func step(symbol: String, title: String, body: NSAttributedString, width: CGFloat) -> NSView {
        let badge = NSView()
        badge.wantsLayer = true
        badge.layer?.cornerRadius = 15
        badge.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        let image = NSImageView(image: NSImage(systemSymbolName: symbol, accessibilityDescription: nil) ?? NSImage())
        image.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        image.contentTintColor = .white
        image.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(image)
        badge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            badge.widthAnchor.constraint(equalToConstant: 30),
            badge.heightAnchor.constraint(equalToConstant: 30),
            image.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
        ])

        let titleLabel = label(title, font: .systemFont(ofSize: 13, weight: .semibold))
        let bodyLabel = NSTextField(wrappingLabelWithString: "")
        let styled = NSMutableAttributedString(attributedString: body)
        styled.addAttributes(
            [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.secondaryLabelColor],
            range: NSRange(location: 0, length: styled.length)
        )
        bodyLabel.attributedStringValue = styled
        bodyLabel.preferredMaxLayoutWidth = width
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.widthAnchor.constraint(equalToConstant: width).isActive = true

        let texts = NSStackView(views: [titleLabel, bodyLabel])
        texts.orientation = .vertical
        texts.alignment = .leading
        texts.spacing = 2
        let row = NSStackView(views: [badge, texts])
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = 14
        return row
    }

    private static func label(_ text: String, font: NSFont, color: NSColor = .labelColor) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = font
        label.textColor = color
        label.alignment = .center
        return label
    }
}
