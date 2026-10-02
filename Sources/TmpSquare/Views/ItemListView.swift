import SwiftUI

/// 項目を一覧表示する。1 項目ずつドラッグして取り出せる
struct ItemListView: View {
    @ObservedObject var model: ShelfModel
    let namespace: Namespace.ID

    /// 表示されたあと、カードが行に着く頃に文字を上から順に表示するためのフラグ
    @State private var isRevealed = false

    var body: some View {
        ScrollView {
            // 移動中のサムネイルが重なったとき先頭の項目を一番上に描くため、zIndex が効く VStack を使う
            VStack(spacing: 2) {
                ForEach(Array(model.items.enumerated()), id: \.element.id) { index, item in
                    ItemRow(item: item, model: model, namespace: namespace, index: index, isRevealed: isRevealed)
                        .zIndex(Double(-index))
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .onAppear { isRevealed = true }
    }
}

struct ItemRow: View {
    @ObservedObject var item: ShelfItem
    let model: ShelfModel
    let namespace: Namespace.ID
    let index: Int
    let isRevealed: Bool

    @State private var isHovering = false

    /// 重ね表示のカードから移動してくるサムネイルか（それ以外は文字と一緒にフェードインする）
    private var thumbnailFliesIn: Bool { index < StackView.visibleCount }

    var body: some View {
        HStack(spacing: 8) {
            // カードから移動してくるものは、最初はカードと同じ傾きで、移動しながらまっすぐにする
            ItemThumbnail(
                item: item,
                size: 30,
                namespace: namespace,
                pose: thumbnailFliesIn && !isRevealed ? StackView.pose(at: index) : .none
            )
            .animation(ShelfMotion.move, value: isRevealed)
            .opacity(thumbnailFliesIn || isRevealed ? 1 : 0)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if let detail = item.detail {
                    Text(detail)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .opacity(isRevealed ? 1 : 0)
            .offset(x: isRevealed ? 0 : -ShelfMotion.revealOffset)
            Spacer(minLength: 22)
        }
        .animation(ShelfMotion.reveal(index: index), value: isRevealed)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(isHovering ? 0.08 : 0))
        )
        .overlay(
            DragSource(
                model: model,
                items: { [item] },
                onDoubleClick: { ItemActions.open([item]) },
                onHover: { isHovering = $0 }
            )
        )
        // ドラッグ用ビューより手前に置いてクリックを受け取れるようにする
        .overlay(alignment: .trailing) {
            if isHovering {
                Button {
                    model.remove([item])
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .help(L("シェルフから外す"))
            }
        }
    }
}
