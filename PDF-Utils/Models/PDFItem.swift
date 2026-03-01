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
    let id = UUID()
    let url: URL
    let fileName: String
    let pageCount: Int
    let fileSize: Int64
    let thumbnail: NSImage

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
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            fileSize = attributes[.size] as? Int64 ?? 0
        } catch {
            fileSize = 0
        }

        // サムネイル生成（1ページ目）
        let thumbnail = generateThumbnail(from: document)

        return PDFItem(
            url: url,
            fileName: url.lastPathComponent,
            pageCount: document.pageCount,
            fileSize: fileSize,
            thumbnail: thumbnail
        )
    }

    // MARK: - Thumbnail

    /// PDFの1ページ目からサムネイルを生成（44×56pt、A4比率）
    private static func generateThumbnail(from document: PDFDocument) -> NSImage {
        let thumbnailSize = NSSize(width: 44, height: 56)

        guard let page = document.page(at: 0) else {
            return NSImage(size: thumbnailSize)
        }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(
            thumbnailSize.width / pageRect.width,
            thumbnailSize.height / pageRect.height
        )

        let image = NSImage(size: thumbnailSize)
        image.lockFocus()

        // 背景を白で塗る
        NSColor.white.setFill()
        NSRect(origin: .zero, size: thumbnailSize).fill()

        // ページを描画
        let scaledWidth = pageRect.width * scale
        let scaledHeight = pageRect.height * scale
        let offsetX = (thumbnailSize.width - scaledWidth) / 2
        let offsetY = (thumbnailSize.height - scaledHeight) / 2

        if let context = NSGraphicsContext.current?.cgContext {
            context.saveGState()
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()
        }

        image.unlockFocus()
        return image
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
