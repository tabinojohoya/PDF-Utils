//
//  PDFItem.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import Foundation
import PDFKit
import AppKit

/// PDFファイル1件を表すモデル
struct PDFItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let fileName: String
    let pageCount: Int
    let fileSize: Int64
    let thumbnail: NSImage
    var pages: [PageItem]

    // MARK: - Hashable

    static func == (lhs: PDFItem, rhs: PDFItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Factory

    /// URLからPDFItemを生成する
    /// - Parameter url: PDFファイルのURL
    /// - Returns: PDFItem（読み込み失敗時はnil）
    /// - Throws: PDFItemError
    static func create(from url: URL) throws -> PDFItem {
        // PDFとして読み込み可能か確認
        guard let document = PDFDocument(url: url) else {
            throw PDFItemError.notReadable(url)
        }

        // パスワード保護チェック
        if document.isLocked {
            throw PDFItemError.passwordProtected(url)
        }

        // ファイルサイズ取得
        let fileSize: Int64
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path(percentEncoded: false))
            fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            fileSize = 0
        }

        // サムネイル生成（1ページ目）
        let thumbnail = ThumbnailGenerator.generate(
            from: document,
            pageIndex: 0,
            size: NSSize(width: 44, height: 56)
        )

        // ページ一覧を生成するために仮IDを先に確定
        let itemID = UUID()

        // 全ページのPageItemを生成
        let pages = (0..<document.pageCount).map { index in
            PageItem.create(from: document, parentID: itemID, pageIndex: index)
        }

        return PDFItem(
            id: itemID,
            url: url,
            fileName: url.lastPathComponent,
            pageCount: document.pageCount,
            fileSize: fileSize,
            thumbnail: thumbnail,
            pages: pages
        )
    }

    // MARK: - Formatted File Size

    /// ファイルサイズを人間可読な文字列に変換
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

// MARK: - Errors

enum PDFItemError: LocalizedError {
    case notReadable(URL)
    case passwordProtected(URL)

    var errorDescription: String? {
        switch self {
        case .notReadable(let url):
            return "\(url.lastPathComponent) を読み込めません。ファイルが破損しているか、PDF形式ではありません。"
        case .passwordProtected(let url):
            return "\(url.lastPathComponent) はパスワードで保護されています。"
        }
    }
}
