//
//  PageItem.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/02.
//

import Foundation
import PDFKit
import AppKit

/// PDFの1ページを表すモデル
struct PageItem: Identifiable, Hashable {
    let id = UUID()
    let parentID: PDFItem.ID
    let pageIndex: Int
    /// サムネイル画像（nil = 未生成、非同期でロードされる）
    var thumbnail: NSImage?
    var isIncluded: Bool = true

    /// ページサムネイルの標準サイズ
    static let thumbnailSize = NSSize(width: 80, height: 104)

    // MARK: - Hashable

    static func == (lhs: PageItem, rhs: PageItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Factory

    /// サムネイル未生成のプレースホルダーを生成する（即座に返る）
    static func placeholder(parentID: PDFItem.ID, pageIndex: Int) -> PageItem {
        PageItem(parentID: parentID, pageIndex: pageIndex, thumbnail: nil)
    }

    /// PDFDocumentの指定ページからPageItemを生成する（同期・サムネイル付き）
    static func create(
        from document: PDFDocument,
        parentID: PDFItem.ID,
        pageIndex: Int
    ) -> PageItem {
        let thumbnail = ThumbnailGenerator.generate(
            from: document,
            pageIndex: pageIndex,
            size: thumbnailSize
        )

        return PageItem(
            parentID: parentID,
            pageIndex: pageIndex,
            thumbnail: thumbnail
        )
    }
}
