//
//  PDFMergeViewModel.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// 表示モード
enum ViewMode: String, CaseIterable {
    case file
    case page
}

/// PDF結合アプリの全状態を一元管理するViewModel
@Observable
final class PDFMergeViewModel {

    // MARK: - State

    /// 追加されたPDFファイルの一覧（表示順 = 結合順）
    var pdfItems: [PDFItem] = []

    /// 現在選択中のアイテムID
    var selectedItemID: PDFItem.ID? = nil

    /// ドラッグ中にウィンドウ上にファイルがあるか
    var isDropTargeted: Bool = false

    /// 結合処理中か
    var isMerging: Bool = false

    /// 結合処理の進捗（0.0〜1.0）
    var mergeProgress: Double = 0.0

    /// エラーメッセージ（Alert表示用）
    var alertMessage: String? = nil

    /// 成功バナーを表示するか
    var showSuccessBanner: Bool = false

    /// 結合後に保存したファイルのURL
    var savedFileURL: URL? = nil

    /// 左ペインの表示モード（ファイル / ページ）
    var viewMode: ViewMode = .file

    /// 出力プレビュー表示中か
    var isShowingMergedPreview: Bool = false

    /// 結合後のPDFファイルURL
    var mergedDocumentURL: URL? = nil

    /// 結合結果のページ数（キャッシュ）
    var mergedPageCount: Int = 0

    /// 結合結果のファイルサイズ文字列（キャッシュ）
    var mergedFileSizeString: String = ""

    /// ページビューで選択中のページID
    var selectedPageID: PageItem.ID? = nil

    // MARK: - Computed Properties

    /// 全ファイルの合計ページ数
    var totalPageCount: Int {
        pdfItems.reduce(0) { $0 + $1.pageCount }
    }

    /// 結合対象のページ数（isIncluded == trueのみ）
    var includedPageCount: Int {
        pdfItems.reduce(0) { total, item in
            total + item.pages.filter(\.isIncluded).count
        }
    }

    /// ファイルが未追加か
    var isEmpty: Bool {
        pdfItems.isEmpty
    }

    /// 結合可能か（結合対象ページが2件以上）
    var canMerge: Bool {
        includedPageCount >= 2
    }

    /// 現在選択中のアイテム
    var selectedItem: PDFItem? {
        guard let id = selectedItemID else { return nil }
        return pdfItems.first { $0.id == id }
    }

    // MARK: - Actions

    /// PDFファイルを追加する
    /// - Parameter urls: 追加するPDFファイルのURL配列
    func addFiles(urls: [URL]) {
        // 結合中は追加を受け付けない
        guard !isMerging else { return }

        var errors: [String] = []
        var skippedDuplicates = 0

        for url in urls {
            // 重複チェック（同一URLは追加しない）
            guard !pdfItems.contains(where: { $0.url == url }) else {
                skippedDuplicates += 1
                continue
            }

            do {
                let item = try PDFItem.create(from: url)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    pdfItems.append(item)
                }
                // ソース変更時は出力プレビューを解除
                dismissMergedPreview()
            } catch {
                errors.append(error.localizedDescription)
            }
        }

        // エラーがあれば一括通知
        if !errors.isEmpty {
            alertMessage = errors.joined(separator: "\n")
        } else if skippedDuplicates > 0 && urls.count == skippedDuplicates {
            alertMessage = "選択されたファイルはすべて追加済みです。"
        }

        // 追加後、最初のアイテムが未選択なら自動選択
        if selectedItemID == nil, let first = pdfItems.first {
            selectedItemID = first.id
        }
    }

    /// 指定したIDのアイテムをリストから削除する
    /// - Parameter ids: 削除するアイテムのID集合
    func removeItems(ids: Set<PDFItem.ID>) {
        guard !isMerging else { return }

        // 削除対象のセキュリティスコープを解放
        for item in pdfItems where ids.contains(item.id) {
            item.url.stopAccessingSecurityScopedResource()
        }

        withAnimation(.easeOut(duration: 0.25)) {
            pdfItems.removeAll { ids.contains($0.id) }
        }

        dismissMergedPreview()

        // 選択中のアイテムが削除された場合、次のアイテムまたは先頭を選択
        if let selectedID = selectedItemID, ids.contains(selectedID) {
            selectedItemID = pdfItems.first?.id
        }
    }

    /// 選択中のアイテムを削除する
    func removeSelectedItem() {
        guard let id = selectedItemID else { return }
        removeItems(ids: [id])
    }

    /// リストを全件クリアする
    func clearAll() {
        guard !isMerging else { return }

        // 全アイテムのセキュリティスコープを解放
        for item in pdfItems {
            item.url.stopAccessingSecurityScopedResource()
        }

        withAnimation(.easeOut(duration: 0.25)) {
            pdfItems.removeAll()
            selectedItemID = nil
            selectedPageID = nil
        }

        dismissMergedPreview()
    }

    // MARK: - Page Operations (v1.1)

    /// ページの結合対象をトグルする
    func togglePageInclusion(pageID: PageItem.ID) {
        guard !isMerging else { return }

        for itemIndex in pdfItems.indices {
            if let pageIndex = pdfItems[itemIndex].pages.firstIndex(where: { $0.id == pageID }) {
                withAnimation(.easeOut(duration: 0.2)) {
                    pdfItems[itemIndex].pages[pageIndex].isIncluded.toggle()
                }
                dismissMergedPreview()
                return
            }
        }
    }

    /// ファイル内の全ページの選択をトグルする
    func toggleAllPages(for fileID: PDFItem.ID) {
        guard !isMerging else { return }
        guard let itemIndex = pdfItems.firstIndex(where: { $0.id == fileID }) else { return }

        let allIncluded = pdfItems[itemIndex].pages.allSatisfy(\.isIncluded)
        let newValue = !allIncluded

        withAnimation(.easeOut(duration: 0.2)) {
            for pageIndex in pdfItems[itemIndex].pages.indices {
                pdfItems[itemIndex].pages[pageIndex].isIncluded = newValue
            }
        }
        dismissMergedPreview()
    }

    /// ファイル内の全ページが含まれているか
    func allPagesIncluded(for fileID: PDFItem.ID) -> Bool {
        guard let item = pdfItems.first(where: { $0.id == fileID }) else { return false }
        return item.pages.allSatisfy(\.isIncluded)
    }

    /// ファイル内の結合対象ページ数
    func includedPageCount(for fileID: PDFItem.ID) -> Int {
        guard let item = pdfItems.first(where: { $0.id == fileID }) else { return 0 }
        return item.pages.filter(\.isIncluded).count
    }

    /// ファイル内でページを並び替える
    func movePage(from source: IndexSet, to destination: Int, in fileID: PDFItem.ID) {
        guard !isMerging else { return }
        guard let itemIndex = pdfItems.firstIndex(where: { $0.id == fileID }) else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems[itemIndex].pages.move(fromOffsets: source, toOffset: destination)
        }
        dismissMergedPreview()
    }

    /// ページを削除する
    func deletePage(pageID: PageItem.ID) {
        guard !isMerging else { return }

        for itemIndex in pdfItems.indices {
            if let pageIndex = pdfItems[itemIndex].pages.firstIndex(where: { $0.id == pageID }) {
                _ = withAnimation(.easeOut(duration: 0.25)) {
                    pdfItems[itemIndex].pages.remove(at: pageIndex)
                }
                // 選択中のページが削除された場合
                if selectedPageID == pageID {
                    selectedPageID = nil
                }
                dismissMergedPreview()
                return
            }
        }
    }

    /// 出力プレビューを解除する
    func dismissMergedPreview() {
        guard isShowingMergedPreview else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            isShowingMergedPreview = false
        }
    }

    /// アイテムを並び替える（List の .onMove 用）
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    func moveItems(from source: IndexSet, to destination: Int) {
        guard !isMerging else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems.move(fromOffsets: source, toOffset: destination)
        }
        dismissMergedPreview()
    }

    /// 選択中のアイテムを1つ上に移動
    func moveSelectedUp() {
        guard let id = selectedItemID,
              let index = pdfItems.firstIndex(where: { $0.id == id }),
              index > 0 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems.swapAt(index, index - 1)
        }
        dismissMergedPreview()
    }

    /// 選択中のアイテムを1つ下に移動
    func moveSelectedDown() {
        guard let id = selectedItemID,
              let index = pdfItems.firstIndex(where: { $0.id == id }),
              index < pdfItems.count - 1 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems.swapAt(index, index + 1)
        }
        dismissMergedPreview()
    }

    /// 成功バナー自動非表示タスク
    private var bannerDismissTask: Task<Void, Never>?

    /// PDF結合を実行する
    /// - Parameter outputURL: 保存先のURL
    func merge(to outputURL: URL) async {
        guard canMerge, !isMerging else { return }

        isMerging = true
        mergeProgress = 0.0

        // ページ単位で結合対象を構築
        let mergeInputs: [(url: URL, pageIndices: [Int])] = pdfItems.compactMap { item in
            let indices = item.pages.filter(\.isIncluded).map(\.pageIndex)
            guard !indices.isEmpty else { return nil }
            return (item.url, indices)
        }

        guard !mergeInputs.isEmpty else {
            alertMessage = "結合対象のページがありません。"
            isMerging = false
            return
        }

        do {
            try await PDFMergeService.merge(inputs: mergeInputs, to: outputURL) { progress in
                Task { @MainActor [weak self] in
                    self?.mergeProgress = progress
                }
            }

            savedFileURL = outputURL
            mergedDocumentURL = outputURL
            showSuccessBanner = true

            // 結合結果の情報をキャッシュ
            if let mergedDoc = PDFDocument(url: outputURL) {
                mergedPageCount = mergedDoc.pageCount
            }
            if let attrs = try? FileManager.default.attributesOfItem(atPath: outputURL.path(percentEncoded: false)),
               let size = attrs[.size] as? Int64 {
                mergedFileSizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            } else {
                mergedFileSizeString = "–"
            }

            // 出力プレビューを表示
            withAnimation(.easeInOut(duration: 0.3)) {
                isShowingMergedPreview = true
            }

            // 前回のタイマーをキャンセルして再設定
            bannerDismissTask?.cancel()
            bannerDismissTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    showSuccessBanner = false
                }
            }
        } catch {
            alertMessage = error.localizedDescription
        }

        isMerging = false
        mergeProgress = 0.0
    }

    /// 結合結果をFinderで表示する
    func revealInFinder() {
        guard let url = savedFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
