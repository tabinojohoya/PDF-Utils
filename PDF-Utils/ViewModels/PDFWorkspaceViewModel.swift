//
//  PDFWorkspaceViewModel.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

/// アプリの動作モード
enum AppMode: String, CaseIterable, Identifiable {
    case merge  // 結合モード
    case split  // 分割モード

    var id: String { rawValue }
}

/// アプリ全体の状態を管理するViewModel（司令塔）
@Observable
final class PDFWorkspaceViewModel {

    // MARK: - Services

    /// セキュリティスコープ管理
    let scopeManager = SecurityScopeManager()

    // MARK: - Mode

    /// 現在の動作モード
    var appMode: AppMode = .merge

    // MARK: - Sub-States

    /// 結合モードの状態
    var merge = MergeState()

    /// 分割モードの状態
    var split = SplitState()

    // MARK: - Common State

    /// 構造化エラー（Alert表示用）
    var currentError: AppError? = nil

    /// ドラッグ中にウィンドウ上にファイルがあるか
    var isDropTargeted: Bool = false

    /// プレビュー表示モード（singlePage / continuous）
    var previewDisplayMode: PreviewDisplayMode = .singlePage

    // MARK: - Computed Properties

    /// 処理中か（結合または分割）
    var isProcessing: Bool {
        merge.isMerging || split.isSplitting
    }

    // MARK: - Merge Actions

    /// PDFファイルを追加する
    /// - Parameter urls: 追加するPDFファイルのURL配列
    func addFiles(urls: [URL]) {
        guard !merge.isMerging else { return }

        var addErrors: [AppError] = []
        var skippedDuplicates = 0

        for url in urls {
            guard !merge.pdfItems.contains(where: { $0.url == url }) else {
                skippedDuplicates += 1
                continue
            }

            guard scopeManager.startAccessing(url) else {
                addErrors.append(.accessDenied(fileName: url.lastPathComponent))
                continue
            }

            do {
                let item = try PDFItem.create(from: url)
                let itemID = item.id
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    merge.pdfItems.append(item)
                }
                loadPageThumbnails(for: itemID)
                dismissMergedPreview()
            } catch {
                addErrors.append(.from(error))
            }
        }

        if let firstError = addErrors.first {
            currentError = firstError
        } else if skippedDuplicates > 0 && urls.count == skippedDuplicates {
            currentError = .duplicateFiles(count: skippedDuplicates)
        }

        if merge.selectedItemID == nil, let first = merge.pdfItems.first {
            merge.selectedItemID = first.id
        }
    }

    /// 指定したIDのアイテムをリストから削除する
    func removeItems(ids: Set<PDFItem.ID>) {
        guard !merge.isMerging else { return }

        for item in merge.pdfItems where ids.contains(item.id) {
            scopeManager.stopAccessing(item.url)
        }

        withAnimation(.easeOut(duration: 0.25)) {
            merge.pdfItems.removeAll { ids.contains($0.id) }
        }

        dismissMergedPreview()

        if let selectedID = merge.selectedItemID, ids.contains(selectedID) {
            merge.selectedItemID = merge.pdfItems.first?.id
        }
    }

    /// 選択中のアイテムを削除する
    func removeSelectedItem() {
        guard let id = merge.selectedItemID else { return }
        removeItems(ids: [id])
    }

    /// リストを全件クリアする
    func clearAll() {
        guard !merge.isMerging else { return }

        for item in merge.pdfItems {
            scopeManager.stopAccessing(item.url)
        }

        withAnimation(.easeOut(duration: 0.25)) {
            merge.pdfItems.removeAll()
            merge.selectedItemID = nil
            merge.selectedPageID = nil
        }

        dismissMergedPreview()
    }

    // MARK: - Page Operations

    /// ページの結合対象をトグルする
    func togglePageInclusion(pageID: PageItem.ID) {
        guard !merge.isMerging else { return }

        for itemIndex in merge.pdfItems.indices {
            if let pageIndex = merge.pdfItems[itemIndex].pages.firstIndex(where: { $0.id == pageID }) {
                withAnimation(.easeOut(duration: 0.2)) {
                    merge.pdfItems[itemIndex].pages[pageIndex].isIncluded.toggle()
                }
                dismissMergedPreview()
                return
            }
        }
    }

    /// ファイル内の全ページの選択をトグルする
    func toggleAllPages(for fileID: PDFItem.ID) {
        guard !merge.isMerging else { return }
        guard let itemIndex = merge.pdfItems.firstIndex(where: { $0.id == fileID }) else { return }

        let allIncluded = merge.pdfItems[itemIndex].pages.allSatisfy(\.isIncluded)
        let newValue = !allIncluded

        withAnimation(.easeOut(duration: 0.2)) {
            for pageIndex in merge.pdfItems[itemIndex].pages.indices {
                merge.pdfItems[itemIndex].pages[pageIndex].isIncluded = newValue
            }
        }
        dismissMergedPreview()
    }

    /// ファイル内でページを並び替える
    func movePage(from source: IndexSet, to destination: Int, in fileID: PDFItem.ID) {
        guard !merge.isMerging else { return }
        guard let itemIndex = merge.pdfItems.firstIndex(where: { $0.id == fileID }) else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            merge.pdfItems[itemIndex].pages.move(fromOffsets: source, toOffset: destination)
        }
        dismissMergedPreview()
    }

    /// ファイル間でページを移動する
    func movePageBetweenFiles(
        pageID: PageItem.ID,
        fromFileID: PDFItem.ID,
        toFileID: PDFItem.ID,
        insertionIndex: Int
    ) {
        guard !merge.isMerging else { return }
        guard let srcIdx = merge.pdfItems.firstIndex(where: { $0.id == fromFileID }),
              let pageIdx = merge.pdfItems[srcIdx].pages.firstIndex(where: { $0.id == pageID }),
              let dstIdx = merge.pdfItems.firstIndex(where: { $0.id == toFileID })
        else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            var page = merge.pdfItems[srcIdx].pages.remove(at: pageIdx)
            page.parentID = toFileID
            let clampedIndex = min(insertionIndex, merge.pdfItems[dstIdx].pages.count)
            merge.pdfItems[dstIdx].pages.insert(page, at: clampedIndex)
        }
        dismissMergedPreview()
    }

    /// ページを削除する
    func deletePage(pageID: PageItem.ID) {
        guard !merge.isMerging else { return }

        for itemIndex in merge.pdfItems.indices {
            if let pageIndex = merge.pdfItems[itemIndex].pages.firstIndex(where: { $0.id == pageID }) {
                _ = withAnimation(.easeOut(duration: 0.25)) {
                    merge.pdfItems[itemIndex].pages.remove(at: pageIndex)
                }
                if merge.selectedPageID == pageID {
                    merge.selectedPageID = nil
                }
                dismissMergedPreview()
                return
            }
        }
    }

    /// 出力プレビューを解除する
    func dismissMergedPreview() {
        guard merge.isShowingMergedPreview else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            merge.isShowingMergedPreview = false
        }
    }

    /// アイテムを並び替える（List の .onMove 用）
    func moveItems(from source: IndexSet, to destination: Int) {
        guard !merge.isMerging else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            merge.pdfItems.move(fromOffsets: source, toOffset: destination)
        }
        dismissMergedPreview()
    }

    /// 選択中のアイテムを1つ上に移動
    func moveSelectedUp() {
        guard let id = merge.selectedItemID,
              let index = merge.pdfItems.firstIndex(where: { $0.id == id }),
              index > 0 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            merge.pdfItems.swapAt(index, index - 1)
        }
        dismissMergedPreview()
    }

    /// 選択中のアイテムを1つ下に移動
    func moveSelectedDown() {
        guard let id = merge.selectedItemID,
              let index = merge.pdfItems.firstIndex(where: { $0.id == id }),
              index < merge.pdfItems.count - 1 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            merge.pdfItems.swapAt(index, index + 1)
        }
        dismissMergedPreview()
    }

    /// 成功バナー自動非表示タスク
    private var bannerDismissTask: Task<Void, Never>?

    /// PDF結合を実行する
    func performMerge(to outputURL: URL) async {
        guard merge.canMerge, !merge.isMerging else { return }

        merge.isMerging = true
        merge.mergeProgress = 0.0

        let mergeInputs: [(url: URL, pageIndices: [Int])] = merge.pdfItems.compactMap { item in
            let indices = item.pages.filter(\.isIncluded).map(\.pageIndex)
            guard !indices.isEmpty else { return nil }
            return (item.url, indices)
        }

        guard !mergeInputs.isEmpty else {
            currentError = .noIncludedPages
            merge.isMerging = false
            return
        }

        do {
            try await PDFMergeService.merge(inputs: mergeInputs, to: outputURL) { progress in
                Task { @MainActor [weak self] in
                    self?.merge.mergeProgress = progress
                }
            }

            merge.savedFileURL = outputURL
            merge.mergedDocumentURL = outputURL
            merge.showSuccessBanner = true

            if let mergedDoc = PDFDocument(url: outputURL) {
                merge.mergedPageCount = mergedDoc.pageCount
            }
            if let attrs = try? FileManager.default.attributesOfItem(atPath: outputURL.path(percentEncoded: false)),
               let size = attrs[.size] as? Int64 {
                merge.mergedFileSizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            } else {
                merge.mergedFileSizeString = "–"
            }

            withAnimation(.easeInOut(duration: 0.3)) {
                merge.isShowingMergedPreview = true
            }

            bannerDismissTask?.cancel()
            bannerDismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    self?.merge.showSuccessBanner = false
                }
            }
        } catch {
            currentError = .from(error)
        }

        merge.isMerging = false
        merge.mergeProgress = 0.0
    }

    /// 結合結果をFinderで表示する
    func revealInFinder() {
        guard let url = merge.savedFileURL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    // MARK: - Split Actions

    /// 分割元PDFを設定する
    func setSplitSource(url: URL) {
        guard !split.isSplitting else { return }

        if let oldURL = split.sourceItem?.url {
            scopeManager.stopAccessing(oldURL)
        }

        guard scopeManager.startAccessing(url) else {
            currentError = .accessDenied(fileName: url.lastPathComponent)
            return
        }

        do {
            let item = try PDFItem.create(from: url)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                split.sourceItem = item
            }
            split.config = SplitConfig()
            split.outputURLs = []
            split.outputDirectory = nil
            split.showSuccessBanner = false
        } catch {
            currentError = .from(error)
        }
    }

    /// 分割成功バナー自動非表示タスク
    private var splitBannerDismissTask: Task<Void, Never>?

    /// PDF分割を実行する
    func performSplit(to outputDirectory: URL) async {
        guard split.canSplit, let source = split.sourceItem else { return }

        guard case .success(let groups) = split.splitGroups else { return }

        split.isSplitting = true
        split.splitProgress = 0.0

        let baseName = source.url.deletingPathExtension().lastPathComponent

        do {
            let urls = try await PDFSplitService.split(
                url: source.url,
                groups: groups,
                to: outputDirectory,
                baseName: baseName
            ) { progress in
                Task { @MainActor [weak self] in
                    self?.split.splitProgress = progress
                }
            }

            split.outputURLs = urls
            split.outputDirectory = outputDirectory
            split.showSuccessBanner = true

            splitBannerDismissTask?.cancel()
            splitBannerDismissTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation(.easeOut(duration: 0.5)) {
                    self?.split.showSuccessBanner = false
                }
            }
        } catch {
            currentError = .from(error)
        }

        split.isSplitting = false
        split.splitProgress = 0.0
    }

    /// 分割結果の出力フォルダをFinderで表示する
    func revealSplitOutputInFinder() {
        guard let dir = split.outputDirectory else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir.path)
    }

    // MARK: - Async Thumbnail Loading

    /// 指定アイテムのページサムネイルを非同期で一括ロードする
    func loadPageThumbnails(for itemID: PDFItem.ID) {
        guard let index = merge.pdfItems.firstIndex(where: { $0.id == itemID }) else { return }
        let url = merge.pdfItems[index].url

        Task.detached(priority: .userInitiated) { [weak self] in
            let thumbnails = await ThumbnailGenerator.generateAll(
                from: url,
                size: PageItem.thumbnailSize
            )

            await MainActor.run {
                guard let self,
                      let itemIdx = self.merge.pdfItems.firstIndex(where: { $0.id == itemID })
                else { return }

                for (pageIndex, image) in thumbnails {
                    guard pageIndex < self.merge.pdfItems[itemIdx].pages.count else { continue }
                    self.merge.pdfItems[itemIdx].pages[pageIndex].thumbnail = image
                }
            }
        }
    }
}
