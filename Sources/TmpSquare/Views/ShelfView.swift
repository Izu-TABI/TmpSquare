import SwiftUI

enum ShelfMetrics {
    static let size = NSSize(width: 220, height: 256)
    static let cornerRadius: CGFloat = 22
}

/// 重ね表示⇄一覧表示を切り替えるときの動きのタイミング
enum ShelfMotion {
    /// サムネイルの移動・拡大縮小（揺れ戻しなし）
    static let move = Animation.smooth(duration: 0.24)
    /// 切り替え前の画面を消す
    static let fadeOut = Animation.easeOut(duration: 0.08)
    /// 文字を表示する。index 番目の項目ほど少しずつ遅らせる
    static func reveal(index: Int = 0) -> Animation {
        .easeOut(duration: 0.16).delay(0.06 + Double(min(index, 8)) * 0.015)
    }
    /// 文字が表示されるときにずらす距離
    static let revealOffset: CGFloat = 4
}

struct ShelfView: View {
    @ObservedObject var model: ShelfModel
    @Namespace private var thumbnails

    /// 重ね表示⇄一覧表示の切り替え。サムネイルは matchedGeometryEffect で移動させるので、
    /// 新しい側はすぐに表示し、古い側だけを素早くフェードアウトする（二重写しを避ける）
    private static let modeTransition = AnyTransition.asymmetric(
        insertion: .identity,
        removal: .opacity.animation(ShelfMotion.fadeOut)
    )

    var body: some View {
        VStack(spacing: 0) {
            ShelfHeader(model: model)
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: ShelfMetrics.size.width, height: ShelfMetrics.size.height)
        .overlay { dropHighlight }
        .overlay {
            if model.isWorking {
                ProgressView()
                    .controlSize(.small)
                    .padding(12)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .animation(.easeOut(duration: 0.15), value: model.isDropTargeted)
        .animation(ShelfMotion.move, value: model.isExpanded)
        .animation(.snappy(duration: 0.25), value: model.items.map(\.id))
    }

    @ViewBuilder
    private var content: some View {
        if model.isExpanded && !model.items.isEmpty {
            ItemListView(model: model, namespace: thumbnails)
                .transition(Self.modeTransition)
        } else {
            StackView(model: model, namespace: thumbnails)
                .transition(Self.modeTransition)
        }
    }

    @ViewBuilder
    private var dropHighlight: some View {
        if model.isDropTargeted && !model.items.isEmpty {
            RoundedRectangle(cornerRadius: ShelfMetrics.cornerRadius - 4, style: .continuous)
                .strokeBorder(Color.accentColor, lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: ShelfMetrics.cornerRadius - 4, style: .continuous)
                        .fill(Color.accentColor.opacity(0.08))
                )
                .padding(4)
                .allowsHitTesting(false)
        }
    }
}

struct ShelfHeader: View {
    @ObservedObject var model: ShelfModel

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .allowsHitTesting(false)

            HStack(spacing: 6) {
                HeaderButton(systemImage: "xmark", help: L("シェルフを閉じる（esc）")) {
                    model.requestClose()
                }
                Spacer()
                if !model.items.isEmpty {
                    HeaderButton(
                        systemImage: model.isExpanded ? "square.stack.3d.up" : "list.bullet",
                        help: model.isExpanded ? L("重ねて表示") : L("一覧で表示")
                    ) {
                        model.isExpanded.toggle()
                    }
                    HeaderButton(systemImage: "ellipsis", help: L("アクション")) {
                        ShelfMenu.make(for: model.items, in: model)
                            .popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 38)
        .background(WindowDragHandle())
    }

    private var title: String {
        model.items.isEmpty ? L("シェルフ") : Localization.itemCount(model.items.count)
    }
}
