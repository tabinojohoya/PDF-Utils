//
//  ThumbnailGenerator.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/02.
//

import Foundation
import PDFKit
import AppKit

/// PDFページのサムネイルを生成するユーティリティ
enum ThumbnailGenerator {

    /// 指定ページのサムネイルを生成する
    /// - Parameters:
    ///   - document: PDFDocument
    ///   - pageIndex: ページインデックス（0始まり）
    ///   - size: 出力サムネイルサイズ
    /// - Returns: サムネイル画像
    static func generate(
        from document: PDFDocument,
        pageIndex: Int = 0,
        size: NSSize
    ) -> NSImage {
        guard let page = document.page(at: pageIndex) else {
            return NSImage(size: size)
        }

        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(
            size.width / pageRect.width,
            size.height / pageRect.height
        )

        let scaledWidth = pageRect.width * scale
        let scaledHeight = pageRect.height * scale
        let offsetX = (size.width - scaledWidth) / 2
        let offsetY = (size.height - scaledHeight) / 2

        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()

            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()
            return true
        }
        return image
    }

    /// PDFPage から直接サムネイルを生成する
    /// - Parameters:
    ///   - page: 対象の PDFPage
    ///   - size: 出力サムネイルサイズ
    /// - Returns: サムネイル画像
    static func generate(from page: PDFPage, size: NSSize) -> NSImage {
        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(
            size.width / pageRect.width,
            size.height / pageRect.height
        )

        let scaledWidth = pageRect.width * scale
        let scaledHeight = pageRect.height * scale
        let offsetX = (size.width - scaledWidth) / 2
        let offsetY = (size.height - scaledHeight) / 2

        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()

            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            context.translateBy(x: offsetX, y: offsetY)
            context.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: context)
            context.restoreGState()
            return true
        }
        return image
    }
}
