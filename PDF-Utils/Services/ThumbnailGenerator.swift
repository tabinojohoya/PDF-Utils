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
///
/// PDFPage は MainActor 分離のため、サムネイル生成も MainActor 上で実行する。
/// バッチ生成時は `Task.yield()` で定期的に制御を返し、UIブロッキングを防ぐ。
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
            return placeholderImage(size: size)
        }
        return generate(from: page, size: size)
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

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return placeholderImage(size: size)
        }

        // 白背景
        context.setFillColor(.white)
        context.fill(CGRect(origin: .zero, size: size))

        // PDFページ描画
        context.saveGState()
        context.translateBy(x: offsetX, y: offsetY)
        context.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: context)
        context.restoreGState()

        guard let cgImage = context.makeImage() else {
            return placeholderImage(size: size)
        }
        return NSImage(cgImage: cgImage, size: size)
    }

    // MARK: - Async Batch Generation

    /// 全ページのサムネイルを一括生成する
    ///
    /// MainActor 上で実行し、5ページごとに `Task.yield()` で
    /// UIスレッドに制御を返してブロッキングを防ぐ。
    /// - Parameters:
    ///   - url: PDFファイルのURL
    ///   - size: 出力サムネイルサイズ
    /// - Returns: ページインデックスとサムネイル画像の辞書
    static func generateAll(
        from url: URL,
        size: NSSize
    ) async -> [Int: NSImage] {
        guard let document = PDFDocument(url: url) else {
            return [Int: NSImage]()
        }
        var results = [Int: NSImage]()
        results.reserveCapacity(document.pageCount)
        for i in 0..<document.pageCount {
            results[i] = generate(from: document, pageIndex: i, size: size)
            // 定期的にyieldしてUIをブロックしない
            if i % 5 == 4 {
                await Task.yield()
            }
        }
        return results
    }

    // MARK: - Private

    /// 空のプレースホルダー画像を生成する
    private static func placeholderImage(size: NSSize) -> NSImage {
        NSImage(size: size)
    }
}
