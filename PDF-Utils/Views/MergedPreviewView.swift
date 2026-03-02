//
//  MergedPreviewView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/02.
//

import SwiftUI
import PDFKit

/// 結合結果の出力プレビュー（右ペイン）
struct MergedPreviewView: View {
    @Environment(PDFMergeViewModel.self) private var viewModel
    let url: URL

    var body: some View {
        VStack(spacing: 0) {
            // 結合済みPDFプレビュー（連続スクロールモード）
            MergedPDFView(url: url)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // フッター: 結果情報 + 編集に戻るボタン
            HStack {
                Button {
                    viewModel.dismissMergedPreview()
                } label: {
                    Label("編集に戻る", systemImage: "chevron.backward")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("編集に戻る")
                .accessibilityHint("ファイル・ページ選択画面に戻ります")

                Spacer()

                // 結合結果の情報
                Text("結合結果: \(viewModel.mergedPageCount)ページ · \(viewModel.mergedFileSizeString)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.bar)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("結合結果のプレビュー")
    }
}

/// 結合済みPDF表示用 — 連続スクロールモード
struct MergedPDFView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .controlBackgroundColor
        return pdfView
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        let currentURL = pdfView.document?.documentURL
        if currentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}
