import SwiftUI

/// 項目を重ねたカードとして表示する。ドラッグすると全項目をまとめて取り出せる。
/// 空のときはドロップの案内を表示する。
struct StackView: View {
    @ObservedObject var model: ShelfModel
    let namespace: Namespace.ID

    /// 上から順に、1 枚目・2 枚目・3 枚目の傾きとずれ
    private static let poses: [CardPose] = [
        .none,
        CardPose(angle: -8, x: -12, y: 3),
        CardPose(angle: 8, x: 12, y: 3),
    ]

    /// 重ねて見せるカードの枚数
    static var visibleCount: Int { poses.count }

    static func pose(at index: Int) -> CardPose {
        index < poses.count ? poses[index] : .none
    }

    /// 一覧表示から戻ってきたとき、カードを広げながら着地させ、そのあと文字を表示するためのフラグ
    @State private var isRevealed = false

    var body: some View {
        ZStack {
            // 空⇄項目ありの切り替えは StackView が表示されたままのときだけ起きるので、
            // 一覧表示から戻るときはここのトランジションは使われず、カードが移動してくる
            if model.items.isEmpty {
                EmptyDropZone(isTargeted: model.isDropTargeted)
                    .transition(.opacity)
            } else {
                stack
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .onAppear { isRevealed = true }
    }

    private var stack: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(Array(model.items.prefix(Self.visibleCount).enumerated()), id: \.element.id) { index, item in
                    ItemThumbnail(
                        item: item,
                        size: 96,
                        namespace: namespace,
                        pose: isRevealed ? Self.pose(at: index) : .none
                    )
                    .animation(ShelfMotion.move, value: isRevealed)
                    .zIndex(Double(-index))
                }
            }
            .frame(height: 120)

            if let first = model.items.first {
                VStack(spacing: 2) {
                    Text(first.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(model.items.count > 1 ? Localization.andMore(model.items.count - 1) : (first.detail ?? ""))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .padding(.horizontal, 16)
                .opacity(isRevealed ? 1 : 0)
                .offset(y: isRevealed ? 0 : ShelfMotion.revealOffset)
                .animation(ShelfMotion.reveal(), value: isRevealed)
            }
        }
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            DragSource(model: model, items: { model.items }, onClick: { model.isExpanded = true })
        )
    }
}
