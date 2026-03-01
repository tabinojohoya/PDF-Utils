//
//  PDFMergeService.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import Foundation
import PDFKit

/// PDF結合処理のコアエンジン
enum PDFMergeService {

    /// 複数のPDFファイルを結合し、指定パスに保存する
    /// - Parameters:
    ///   - urls: 結合するPDFファイルのURL配列（順序通り）
    ///   - outputURL: 保存先URL
    ///   - progress: 進捗コールバック (0.0〜1.0)
    /// - Throws: PDFMergeError
    nonisolated static func merge(
        urls: [URL],
        to outputURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws {
        // 重い処理をバックグラウンドスレッドで実行
        try await Task.detached(priority: .userInitiated) {
            guard !urls.isEmpty else {
                throw PDFMergeError.noFiles
            }

            // 全ファイルの合計ページ数を先に計算（進捗計算用）
            let documents: [(url: URL, document: PDFDocument)] = try urls.map { url in
                guard let doc = PDFDocument(url: url) else {
                    throw PDFMergeError.fileNotReadable(url)
                }
                if doc.isLocked {
                    throw PDFMergeError.passwordProtected(url)
                }
                return (url, doc)
            }

            let totalPages = documents.reduce(0) { $0 + $1.document.pageCount }
            guard totalPages > 0 else {
                throw PDFMergeError.noFiles
            }

            // 結合処理（バックグラウンドで実行）
            let outputDocument = PDFDocument()
            var insertedPages = 0

            for (_, document) in documents {
                for pageIndex in 0..<document.pageCount {
                    guard let page = document.page(at: pageIndex) else { continue }

                    outputDocument.insert(page, at: outputDocument.pageCount)
                    insertedPages += 1

                    // 進捗を報告
                    let currentProgress = Double(insertedPages) / Double(totalPages)
                    progress(currentProgress)
                }
            }

            // ファイルに書き出し
            guard outputDocument.write(to: outputURL) else {
                throw PDFMergeError.writeFailed(outputURL)
            }

            progress(1.0)
        }.value
    }
}

// MARK: - Errors

enum PDFMergeError: LocalizedError {
    case fileNotReadable(URL)
    case passwordProtected(URL)
    case writeFailed(URL)
    case noFiles

    var errorDescription: String? {
        switch self {
        case .fileNotReadable(let url):
            return "\(url.lastPathComponent) を読み込めませんでした。"
        case .passwordProtected(let url):
            return "\(url.lastPathComponent) はパスワードで保護されています。"
        case .writeFailed(let url):
            return "\(url.path) への書き込みに失敗しました。"
        case .noFiles:
            return "結合するファイルがありません。"
        }
    }
}
