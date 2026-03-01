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

    // MARK: - Computed Properties

    /// 全ファイルの合計ページ数
    var totalPageCount: Int {
        pdfItems.reduce(0) { $0 + $1.pageCount }
    }

    /// ファイルが未追加か
    var isEmpty: Bool {
        pdfItems.isEmpty
    }

    /// 結合可能か（2ファイル以上）
    var canMerge: Bool {
        pdfItems.count >= 2
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
        for url in urls {
            // 重複チェック（同一URLは追加しない）
            guard !pdfItems.contains(where: { $0.url == url }) else {
                continue
            }

            do {
                let item = try PDFItem.create(from: url)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    pdfItems.append(item)
                }
            } catch {
                alertMessage = error.localizedDescription
            }
        }

        // 追加後、最初のアイテムが未選択なら自動選択
        if selectedItemID == nil, let first = pdfItems.first {
            selectedItemID = first.id
        }
    }

    /// 指定したIDのアイテムをリストから削除する
    /// - Parameter ids: 削除するアイテムのID集合
    func removeItems(ids: Set<PDFItem.ID>) {
        withAnimation(.easeOut(duration: 0.25)) {
            pdfItems.removeAll { ids.contains($0.id) }
        }

        // 選択中のアイテムが削除された場合、選択をリセット
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
        withAnimation(.easeOut(duration: 0.25)) {
            pdfItems.removeAll()
            selectedItemID = nil
        }
    }

    /// アイテムを並び替える（List の .onMove 用）
    /// - Parameters:
    ///   - source: 移動元のインデックス
    ///   - destination: 移動先のインデックス
    func moveItems(from source: IndexSet, to destination: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems.move(fromOffsets: source, toOffset: destination)
        }
    }

    /// 選択中のアイテムを1つ上に移動
    func moveSelectedUp() {
        guard let id = selectedItemID,
              let index = pdfItems.firstIndex(where: { $0.id == id }),
              index > 0 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems.swapAt(index, index - 1)
        }
    }

    /// 選択中のアイテムを1つ下に移動
    func moveSelectedDown() {
        guard let id = selectedItemID,
              let index = pdfItems.firstIndex(where: { $0.id == id }),
              index < pdfItems.count - 1 else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            pdfItems.swapAt(index, index + 1)
        }
    }

    /// PDF結合を実行する
    /// - Parameter outputURL: 保存先のURL
    func merge(to outputURL: URL) async {
        guard canMerge else { return }

        isMerging = true
        mergeProgress = 0.0

        let urls = pdfItems.map(\.url)

        do {
            try await PDFMergeService.merge(urls: urls, to: outputURL) { [weak self] progress in
                Task { @MainActor in
                    self?.mergeProgress = progress
                }
            }

            savedFileURL = outputURL
            showSuccessBanner = true

            // 5秒後にバナーを非表示
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(5))
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
