//
//  MergeState.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import Foundation

/// 結合モードの状態を保持する構造体
struct MergeState {

    /// 追加されたPDFファイルの一覧（表示順 = 結合順）
    var pdfItems: [PDFItem] = []

    /// 現在選択中のアイテムID
    var selectedItemID: PDFItem.ID? = nil

    /// 表示モード（ファイルリスト or ページグリッド）
    enum ViewMode: String, CaseIterable {
        case file   // ファイルリスト表示
        case page   // ページサムネイル表示
    }

    /// 現在の表示モード
    var viewMode: ViewMode = .file

    /// 現在選択中のページID（ページビュー用）
    var selectedPageID: PageItem.ID? = nil

    /// 結合処理中か
    var isMerging: Bool = false

    /// 結合処理の進捗（0.0〜1.0）
    var mergeProgress: Double = 0.0

    /// 成功バナーを表示するか
    var showSuccessBanner: Bool = false

    /// 結合後に保存したファイルのURL
    var savedFileURL: URL? = nil

    /// 結合結果プレビューを表示中か
    var isShowingMergedPreview: Bool = false

    /// 結合結果のURL（プレビュー用）
    var mergedDocumentURL: URL? = nil

    /// 結合結果のページ数（プレビュー表示用）
    var mergedPageCount: Int = 0

    /// 結合結果のファイルサイズ文字列（プレビュー表示用）
    var mergedFileSizeString: String = ""

    // MARK: - Computed Properties

    /// ファイルが未追加か
    var isEmpty: Bool {
        pdfItems.isEmpty
    }

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

    /// 結合可能か（結合対象ページが2件以上）
    var canMerge: Bool {
        includedPageCount >= 2
    }

    /// 現在選択中のアイテム
    var selectedItem: PDFItem? {
        guard let id = selectedItemID else { return nil }
        return pdfItems.first { $0.id == id }
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
}
