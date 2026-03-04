//
//  SplitState.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import Foundation

/// 分割モードの状態を保持する構造体
struct SplitState {

    /// 分割元のPDFアイテム
    var sourceItem: PDFItem? = nil

    /// 分割設定
    var config: SplitConfig = SplitConfig()

    /// 分割処理中か
    var isSplitting: Bool = false

    /// 分割処理の進捗（0.0〜1.0）
    var splitProgress: Double = 0.0

    /// 分割後に生成されたファイルのURL配列
    var outputURLs: [URL] = []

    /// 分割出力先ディレクトリ
    var outputDirectory: URL? = nil

    /// 分割成功バナーを表示するか
    var showSuccessBanner: Bool = false

    // MARK: - Computed Properties

    /// 分割グループのリアルタイム計算結果
    var splitGroups: Result<[[Int]], SplitConfigError> {
        guard let source = sourceItem else {
            return .failure(.emptyResult)
        }
        return config.computeGroups(totalPages: source.pageCount)
    }

    /// 分割可能か（ソースファイルがあり、有効な分割設定）
    var canSplit: Bool {
        guard sourceItem != nil, !isSplitting else { return false }
        if case .success = splitGroups { return true }
        return false
    }
}
