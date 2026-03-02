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
    let thumbnail: NSImage
    var isIncluded: Bool = true

    // MARK: - Hashable

    static func == (lhs: PageItem, rhs: PageItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Factory

    /// PDFDocumentの指定ページからPageItemを生成する
    static func create(
        from document: PDFDocument,
        parentID: PDFItem.ID,
        pageIndex: Int
    ) -> PageItem {
        let thumbnail = ThumbnailGenerator.generate(
            from: document,
            pageIndex: pageIndex,
            size: NSSize(width: 80, height: 104)
        )

        return PageItem(
            parentID: parentID,
            pageIndex: pageIndex,
            thumbnail: thumbnail
        )
    }
}
