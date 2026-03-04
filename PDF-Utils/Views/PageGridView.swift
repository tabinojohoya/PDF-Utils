//
//  PageGridView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/02.
//

import SwiftUI

/// ページビュー — ファイルごとのセクション付きサムネイルグリッド
struct PageGridView: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel

    /// グリッドカラム定義（80pt幅のサムネイルを並べる）
    private let columns = [
        GridItem(.adaptive(minimum: 92, maximum: 120), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.merge.pdfItems) { item in
                    fileSection(for: item)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 320)
        .accessibilityLabel("ページ一覧")
    }

    // MARK: - File Section

    @ViewBuilder
    private func fileSection(for item: PDFItem) -> some View {
        DisclosureGroup {
            pageGrid(for: item)
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
        } label: {
            fileSectionHeader(for: item)
        }
        .padding(.horizontal, 8)
        .disclosureGroupStyle(.automatic)
        .dropDestination(for: String.self) { droppedItems, _ in
            handleCrossFileDrop(droppedItems: droppedItems, targetFileID: item.id)
        } isTargeted: { _ in }
    }

    // MARK: - File Section Header

    private func fileSectionHeader(for item: PDFItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text("\(viewModel.merge.includedPageCount(for: item.id))/\(item.pageCount)ページ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // 全選択/全解除トグル
            Button {
                viewModel.toggleAllPages(for: item.id)
            } label: {
                Image(systemName: viewModel.merge.allPagesIncluded(for: item.id)
                      ? "checkmark.square.fill"
                      : (viewModel.merge.includedPageCount(for: item.id) > 0
                         ? "minus.square.fill"
                         : "square"))
                    .font(.body)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.merge.allPagesIncluded(for: item.id)
                                ? "全ページを除外"
                                : "全ページを選択")
            .disabled(viewModel.merge.isMerging)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Page Grid

    private func pageGrid(for item: PDFItem) -> some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(item.pages) { page in
                PageThumbnailView(
                    page: page,
                    isSelected: viewModel.merge.selectedPageID == page.id,
                    onToggleInclusion: {
                        viewModel.togglePageInclusion(pageID: page.id)
                    },
                    onSelect: {
                        viewModel.merge.selectedPageID = page.id
                        // プレビュー連動: 親ファイルを選択
                        viewModel.merge.selectedItemID = item.id
                    }
                )
                .draggable(page.id.uuidString) {
                    // ドラッグ中のプレビュー
                    if let thumbnail = page.thumbnail {
                        Image(nsImage: thumbnail)
                            .resizable()
                            .frame(width: 60, height: 78)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .opacity(0.8)
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 78)
                    }
                }
            }
            .onMove { source, destination in
                viewModel.movePage(from: source, to: destination, in: item.id)
            }
        }
    }

    // MARK: - Cross-File Drop

    /// ファイル間ページドロップを処理する
    private func handleCrossFileDrop(droppedItems: [String], targetFileID: PDFItem.ID) -> Bool {
        guard let pageIDString = droppedItems.first,
              let pageID = UUID(uuidString: pageIDString) else { return false }

        // ドロップ元のファイルを特定
        guard let sourceItem = viewModel.merge.pdfItems.first(where: { item in
            item.pages.contains(where: { $0.id == pageID })
        }) else { return false }

        // 同一ファイル内のドロップは .onMove に任せる
        guard sourceItem.id != targetFileID else { return false }

        // ターゲットファイルの末尾に挿入
        let targetItem = viewModel.merge.pdfItems.first(where: { $0.id == targetFileID })
        let insertionIndex = targetItem?.pages.count ?? 0

        viewModel.movePageBetweenFiles(
            pageID: pageID,
            fromFileID: sourceItem.id,
            toFileID: targetFileID,
            insertionIndex: insertionIndex
        )
        return true
    }
}

// MARK: - Zero Pages Warning

/// 全ページ除外されたファイルがあるかチェックし、警告を表示するビュー
struct ZeroPagesWarningView: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel

    /// 全ページ除外されたファイルがあるか
    private var hasZeroPageFiles: Bool {
        viewModel.merge.pdfItems.contains { item in
            !item.pages.isEmpty && item.pages.allSatisfy { !$0.isIncluded }
        }
    }

    var body: some View {
        if hasZeroPageFiles {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("0ページのファイルがあります")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("警告: 0ページのファイルがあります")
        }
    }
}
