//
//  SplitPreviewView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/03.
//

import SwiftUI
import PDFKit
import AppKit

/// 分割プレビュー（右ペイン） — ページサムネイルグリッドで分割結果を視覚的に表示
struct SplitPreviewView: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel

    /// グリッドのカラム定義（80pt幅、可変数）
    private let columns = [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 12)]

    /// サムネイルサイズ（80×104pt、A4比率）
    private static let thumbnailSize = NSSize(width: 80, height: 104)

    /// ページサムネイルキャッシュ
    @State private var pageThumbnails: [Int: NSImage] = [:]

    /// 現在キャッシュ済みのソースURL（ソース変更時にキャッシュをリセット）
    @State private var cachedSourceURL: URL? = nil

    var body: some View {
        Group {
            if let source = viewModel.split.sourceItem {
                previewContent(source: source)
            } else {
                emptyPreview
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: viewModel.split.sourceItem?.url) { _, newURL in
            if newURL != cachedSourceURL {
                pageThumbnails.removeAll()
                cachedSourceURL = newURL
                if let url = newURL {
                    generateAllThumbnails(url: url)
                }
            }
        }
        .onAppear {
            if let url = viewModel.split.sourceItem?.url, pageThumbnails.isEmpty {
                cachedSourceURL = url
                generateAllThumbnails(url: url)
            }
        }
    }

    // MARK: - Preview Content

    @ViewBuilder
    private func previewContent(source: PDFItem) -> some View {
        let groupsResult = viewModel.split.splitGroups

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                switch groupsResult {
                case .success(let groups):
                    groupedGridView(groups: groups, totalPages: source.pageCount)
                case .failure:
                    // 設定が無効な場合: 全ページをフラットにグリッド表示 + 警告
                    invalidConfigWarning
                    flatGridView(totalPages: source.pageCount)
                }
            }
            .padding(16)
        }
        .background(.background)
    }

    // MARK: - Grouped Grid (valid split config)

    private func groupedGridView(groups: [[Int]], totalPages: Int) -> some View {
        ForEach(Array(groups.enumerated()), id: \.offset) { groupIndex, group in
            // グループヘッダー
            VStack(alignment: .leading, spacing: 8) {
                if groupIndex > 0 {
                    splitDivider
                }

                Text("Part \(groupIndex + 1)（\(group.count)ページ）")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.top, groupIndex > 0 ? 4 : 0)
                    .accessibilityLabel("パート\(groupIndex + 1)、\(group.count)ページ")

                // グリッド
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(group, id: \.self) { pageIndex in
                        pageThumbnailView(pageIndex: pageIndex)
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(groupIndex.isMultiple(of: 2) ? Color.primary.opacity(0.03) : Color.clear)
                )
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("パート\(groupIndex + 1)")
            .accessibilityValue("\(group.count)ページ")
        }
    }

    // MARK: - Flat Grid (invalid config)

    private func flatGridView(totalPages: Int) -> some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            ForEach(0..<totalPages, id: \.self) { pageIndex in
                pageThumbnailView(pageIndex: pageIndex)
            }
        }
    }

    // MARK: - Page Thumbnail

    private func pageThumbnailView(pageIndex: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            // サムネイル画像
            Group {
                if let thumbnail = pageThumbnails[pageIndex] {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(.quaternary)
                }
            }
            .frame(width: 80, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            // ページ番号ラベル（1-based表示）
            Text("\(pageIndex + 1)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 2))
                .padding(3)
        }
        .accessibilityLabel("ページ\(pageIndex + 1)")
    }

    // MARK: - Split Divider

    private var splitDivider: some View {
        HStack(spacing: 6) {
            Image(systemName: "scissors")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
        .accessibilityHidden(true)
    }

    // MARK: - Invalid Config Warning

    private var invalidConfigWarning: some View {
        Label("分割設定を完了すると、ここに分割プレビューが表示されます", systemImage: "info.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.bottom, 12)
            .accessibilityLabel("分割設定が未完了です。左ペインで分割方法を設定してください")
    }

    // MARK: - Empty Preview

    private var emptyPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.split.2x1")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
                .accessibilityHidden(true)

            Text("PDFを選択してプレビュー")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .accessibilityLabel("プレビュー領域。PDFを選択してください")
    }

    // MARK: - Thumbnail Generation

    /// 全ページのサムネイルを非同期生成
    private func generateAllThumbnails(url: URL) {
        let size = Self.thumbnailSize
        Task.detached(priority: .userInitiated) {
            guard let document = PDFDocument(url: url) else { return }
            let totalPages = document.pageCount

            for pageIndex in 0..<totalPages {
                guard let page = document.page(at: pageIndex) else { continue }
                let thumbnail = ThumbnailGenerator.generate(from: page, size: size)

                await MainActor.run {
                    pageThumbnails[pageIndex] = thumbnail
                }
            }
        }
    }
}
