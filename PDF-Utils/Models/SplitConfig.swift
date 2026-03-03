//
//  SplitConfig.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/03.
//

import Foundation

/// 分割方式を表す列挙型
enum SplitMethod: String, CaseIterable, Identifiable {
    case pageRanges   // ページ範囲指定
    case everyPage    // 1ページずつ
    case oddEven      // 偶数/奇数

    var id: String { rawValue }
}

/// 分割設定
struct SplitConfig {
    var method: SplitMethod = .pageRanges
    var rangeText: String = ""  // "1-3, 4-10, 11-15"

    /// 設定からページ範囲グループを算出する
    /// - Parameter totalPages: PDFの総ページ数
    /// - Returns: 0-basedページインデックスのグループ配列、またはエラー
    func computeGroups(totalPages: Int) -> Result<[[Int]], SplitConfigError> {
        guard totalPages > 0 else {
            return .failure(.emptyResult)
        }

        switch method {
        case .pageRanges:
            return computePageRangeGroups(totalPages: totalPages)
        case .everyPage:
            return computeEveryPageGroups(totalPages: totalPages)
        case .oddEven:
            return computeOddEvenGroups(totalPages: totalPages)
        }
    }

    // MARK: - Private

    /// ページ範囲指定モードのグループ算出
    private func computePageRangeGroups(totalPages: Int) -> Result<[[Int]], SplitConfigError> {
        let trimmed = rangeText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return .failure(.invalidFormat("ページ範囲を入力してください"))
        }

        // カンマ区切りで分割
        let parts = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        var groups: [[Int]] = []
        var allSpecifiedPages: Set<Int> = []

        for part in parts {
            // "1-3" or "5" の形式を解析（空のサブシーケンスを保持して不正入力を検出）
            let rangeParts = part.split(separator: "-", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard rangeParts.count == 1 || rangeParts.count == 2 else {
                return .failure(.invalidFormat("不正な範囲指定: \(part)"))
            }

            guard let start = Int(rangeParts[0]) else {
                return .failure(.invalidFormat("数値として解析できません: \(rangeParts[0])"))
            }

            let end: Int
            if rangeParts.count == 2 {
                guard let e = Int(rangeParts[1]) else {
                    return .failure(.invalidFormat("数値として解析できません: \(rangeParts[1])"))
                }
                end = e
            } else {
                end = start
            }

            // 範囲の妥当性チェック
            guard start >= 1 else {
                return .failure(.pageOutOfRange(start, max: totalPages))
            }
            guard end <= totalPages else {
                return .failure(.pageOutOfRange(end, max: totalPages))
            }
            guard start <= end else {
                return .failure(.invalidFormat("開始ページが終了ページより大きいです: \(part)"))
            }

            // 重複チェック
            let pageSet = Set(start...end)
            if !allSpecifiedPages.isDisjoint(with: pageSet) {
                return .failure(.overlappingRanges)
            }
            allSpecifiedPages.formUnion(pageSet)

            // 1-based → 0-based に変換
            let group = (start...end).map { $0 - 1 }
            groups.append(group)
        }

        // 未指定ページを末尾グループに追加
        let allPages = Set(1...totalPages)
        let unspecified = allPages.subtracting(allSpecifiedPages).sorted()
        if !unspecified.isEmpty {
            let remainingGroup = unspecified.map { $0 - 1 }  // 0-based
            groups.append(remainingGroup)
        }

        guard !groups.isEmpty else {
            return .failure(.emptyResult)
        }

        return .success(groups)
    }

    /// 1ページずつモードのグループ算出
    private func computeEveryPageGroups(totalPages: Int) -> Result<[[Int]], SplitConfigError> {
        let groups = (0..<totalPages).map { [$0] }
        return .success(groups)
    }

    /// 偶数/奇数モードのグループ算出
    private func computeOddEvenGroups(totalPages: Int) -> Result<[[Int]], SplitConfigError> {
        let oddPages = stride(from: 0, to: totalPages, by: 2).map { $0 }   // 0-based: 0, 2, 4, ... = 1, 3, 5ページ目
        let evenPages = stride(from: 1, to: totalPages, by: 2).map { $0 }  // 0-based: 1, 3, 5, ... = 2, 4, 6ページ目

        var groups: [[Int]] = []
        if !oddPages.isEmpty { groups.append(oddPages) }
        if !evenPages.isEmpty { groups.append(evenPages) }

        guard !groups.isEmpty else {
            return .failure(.emptyResult)
        }

        return .success(groups)
    }
}

/// 分割設定のエラー
enum SplitConfigError: LocalizedError {
    case invalidFormat(String)
    case pageOutOfRange(Int, max: Int)
    case overlappingRanges
    case emptyResult

    var errorDescription: String? {
        switch self {
        case .invalidFormat(let detail):
            return "入力形式が不正です: \(detail)"
        case .pageOutOfRange(let page, let max):
            return "ページ \(page) は範囲外です（1〜\(max)）"
        case .overlappingRanges:
            return "ページ範囲が重複しています"
        case .emptyResult:
            return "分割結果が空です"
        }
    }
}
