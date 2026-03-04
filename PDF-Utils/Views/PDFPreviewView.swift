//
//  PDFPreviewView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI
import PDFKit

/// プレビュー表示モード
enum PreviewDisplayMode: String {
    case singlePage
    case continuous
}

/// PDFプレビュー（右ペイン）— PDFView を NSViewRepresentable でラップ
struct PDFPreviewView: NSViewRepresentable {
    let url: URL
    let displayMode: PreviewDisplayMode

    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = displayMode == .continuous ? .singlePageContinuous : .singlePage
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
        // 表示モード変更チェック
        let targetMode: PDFDisplayMode = displayMode == .continuous ? .singlePageContinuous : .singlePage
        if pdfView.displayMode != targetMode {
            pdfView.displayMode = targetMode
        }
    }
}

/// プレビューペイン全体（未選択時のプレースホルダーを含む）
struct PDFPreviewPane: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel
    let selectedItem: PDFItem?

    var body: some View {
        @Bindable var vm = viewModel

        Group {
            if let item = selectedItem {
                VStack(spacing: 0) {
                    // 表示モード切替ツールバー
                    HStack {
                        Spacer()
                        Picker("表示", selection: $vm.previewDisplayMode) {
                            Image(systemName: "doc")
                                .tag(PreviewDisplayMode.singlePage)
                                .accessibilityLabel("単一ページ")
                            Image(systemName: "rectangle.split.1x2")
                                .tag(PreviewDisplayMode.continuous)
                                .accessibilityLabel("連続スクロール")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 80)
                        .padding(6)
                    }
                    .background(.bar)

                    PDFPreviewView(url: item.url, displayMode: viewModel.previewDisplayMode)
                }
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
