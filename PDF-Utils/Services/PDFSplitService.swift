//
//  PDFSplitService.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/03.
//

import Foundation
import PDFKit

/// PDF分割処理のコアエンジン
enum PDFSplitService {

    /// PDFファイルを分割し、指定フォルダに複数ファイルとして保存する
    /// - Parameters:
    ///   - url: 分割元PDFのURL
    ///   - groups: ページインデックスのグループ配列（0-based）
    ///   - outputDirectory: 保存先ディレクトリURL
    ///   - baseName: 出力ファイルのベース名
    ///   - progress: 進捗コールバック (0.0〜1.0)
    /// - Returns: 生成されたファイルのURL配列
    nonisolated static func split(
        url: URL,
        groups: [[Int]],
        to outputDirectory: URL,
        baseName: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> [URL] {
        // 重い処理をバックグラウンドスレッドで実行
        try await Task.detached(priority: .userInitiated) {
            guard !groups.isEmpty else {
                throw PDFSplitError.noGroups
            }

            // 元PDFを読み込み
            guard let sourceDocument = PDFDocument(url: url) else {
                throw PDFSplitError.fileNotReadable(url)
            }

            // パスワード保護チェック
            if sourceDocument.isLocked {
                throw PDFSplitError.passwordProtected(url)
            }

            var outputURLs: [URL] = []
            let totalGroups = groups.count

            for (index, group) in groups.enumerated() {
                // 新規PDFDocumentを生成
                let partDocument = PDFDocument()

                // グループ内のページを順に追加
                for pageIndex in group {
                    guard let page = sourceDocument.page(at: pageIndex) else { continue }
                    partDocument.insert(page, at: partDocument.pageCount)
                }

                // 出力ファイルURLを生成
                let fileName = "\(baseName)_part\(index + 1).pdf"
                let outputURL = outputDirectory.appendingPathComponent(fileName)

                // ファイルに書き出し
                guard partDocument.write(to: outputURL) else {
                    throw PDFSplitError.writeFailed(outputURL)
                }

                outputURLs.append(outputURL)

                // 進捗を報告
                let currentProgress = Double(index + 1) / Double(totalGroups)
                progress(currentProgress)
            }

            progress(1.0)
            return outputURLs
        }.value
    }
}

// MARK: - Errors

enum PDFSplitError: LocalizedError {
    case fileNotReadable(URL)
    case passwordProtected(URL)
    case writeFailed(URL)
    case noGroups

    var errorDescription: String? {
        switch self {
        case .fileNotReadable(let url):
            return "\(url.lastPathComponent) を読み込めませんでした。"
        case .passwordProtected(let url):
            return "\(url.lastPathComponent) はパスワードで保護されています。"
        case .writeFailed(let url):
            return "\(url.path) への書き込みに失敗しました。"
        case .noGroups:
            return "分割するグループが指定されていません。"
        }
    }
}
