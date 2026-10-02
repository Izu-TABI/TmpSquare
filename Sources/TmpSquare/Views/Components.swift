import SwiftUI

struct HeaderButton: View {
    let systemImage: String
    let help: String
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 10, weight: .bold))
                // 既定の速さだとサムネイルの移動より遅れて見えるので速める
                .contentTransition(.symbolEffect(.replace, options: .speed(2.5)))
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.primary.opacity(isHovering ? 0.15 : 0.07)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(help)
        .onHover { isHovering = $0 }
    }
}

/// 重ね表示でのカードの傾きとずれ
struct CardPose: Equatable {
    var angle: Double = 0
    var x: CGFloat = 0
    var y: CGFloat = 0

    static let none = CardPose()
}

struct ItemThumbnail: View {
    @ObservedObject var item: ShelfItem
    let size: CGFloat
    /// 指定すると、重ね表示と一覧表示の間で同じ項目のサムネイルが移動・拡大縮小して見える
    var namespace: Namespace.ID? = nil
    var pose: CardPose = .none

    var body: some View {
        Image(nsImage: item.thumbnail)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: item.hasPreview ? size * 0.06 : 0, style: .continuous))
            .shadow(color: .black.opacity(item.hasPreview ? 0.25 : 0.12), radius: item.hasPreview ? 3 : 1.5, y: 1)
            // 傾きは画像自身の中心で回すため、移動（matchedGeometry）より内側に付ける
            .rotationEffect(.degrees(pose.angle))
            .offset(x: pose.x, y: pose.y)
            // 固定サイズの frame より内側に付けないと、移動中に大きさが変わらない
            .matchedGeometry(id: item.id, in: namespace)
            .frame(width: size, height: size)
    }
}

private extension View {
    @ViewBuilder
    func matchedGeometry(id: some Hashable, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedGeometryEffect(id: id, in: namespace)
        } else {
            self
        }
    }
}

struct EmptyDropZone: View {
    let isTargeted: Bool

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: isTargeted ? "tray.and.arrow.down.fill" : "tray.and.arrow.down")
                .font(.system(size: 34, weight: .light))
            Text(isTargeted ? L("ドロップして追加") : L("ここにドロップ"))
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(isTargeted ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.45),
                    style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.accentColor.opacity(isTargeted ? 0.1 : 0))
                )
        }
        .background(WindowDragHandle())
        .padding([.horizontal, .bottom], 12)
        .scaleEffect(isTargeted ? 1.02 : 1)
    }
}
