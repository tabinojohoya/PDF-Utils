//
//  PageThumbnailView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/02.
//

import SwiftUI

/// ページサムネイル1枚（チェックボックス付き）
struct PageThumbnailView: View {
    let page: PageItem
    let isSelected: Bool
    let onToggleInclusion: () -> Void
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            // サムネイル画像
            ZStack(alignment: .topLeading) {
                Image(nsImage: page.thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                    .opacity(page.isIncluded ? 1.0 : 0.35)

                // 除外時のオーバーレイ
                if !page.isIncluded {
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.background.opacity(0.5))
                            .frame(width: 80, height: 104)

                        Image(systemName: "eye.slash")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                // チェックボックス
                Button {
                    onToggleInclusion()
                } label: {
                    Image(systemName: page.isIncluded ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundStyle(page.isIncluded ? .blue : .secondary)
                        .background(
                            Circle()
                                .fill(.background)
                                .frame(width: 14, height: 14)
                        )
                }
                .buttonStyle(.plain)
                .padding(4)
                .accessibilityLabel(page.isIncluded ? "結合対象から除外" : "結合対象に含める")
            }
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    onSelect()
                }
            )

            // ページ番号ラベル
            Text("p.\(page.pageIndex + 1)")
                .font(.caption2)
                .foregroundStyle(page.isIncluded ? .primary : .secondary)
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("ページ\(page.pageIndex + 1)、\(page.isIncluded ? "含む" : "除外")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: page.isIncluded ? "除外" : "含める") {
            onToggleInclusion()
        }
        .accessibilityAction(named: "選択") {
            onSelect()
        }
    }
}
