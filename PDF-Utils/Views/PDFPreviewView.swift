//
//  PDFPreviewView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI
import PDFKit

/// PDFプレビュー（右ペイン）— PDFView を NSViewRepresentable でラップ
struct PDFPreviewView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .controlBackgroundColor
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        // URLが変わった場合のみドキュメントを差し替え
        let currentURL = pdfView.document?.documentURL
        if currentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}

/// プレビューペイン全体（未選択時のプレースホルダーを含む）
struct PDFPreviewPane: View {
    let selectedItem: PDFItem?

    var body: some View {
        Group {
            if let item = selectedItem {
                PDFPreviewView(url: item.url)
                    .transition(.opacity)
            } else {
                emptyPreview
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: selectedItem?.id)
    }

    private var emptyPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
                .accessibilityHidden(true)

            Text("PDFを選択してプレビュー")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .accessibilityLabel("プレビュー領域。PDFを選択してください")
    }
}
