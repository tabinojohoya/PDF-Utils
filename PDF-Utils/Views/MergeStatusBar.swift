//
//  MergeStatusBar.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI

/// 結合モードのステータスバー
struct MergeStatusBar: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel

    private var statusText: String {
        "\(viewModel.merge.pdfItems.count)ファイル · 合計\(viewModel.merge.includedPageCount)ページ"
    }

    var body: some View {
        HStack {
            Label(statusText, systemImage: "doc.text")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.merge.viewMode == .page {
                ZeroPagesWarningView()
            }

            Spacer()

            if viewModel.merge.isMerging {
                ProgressView(value: viewModel.merge.mergeProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 120)
                    .transition(.opacity)
                    .accessibilityLabel("結合の進捗")
                    .accessibilityValue("\(Int(viewModel.merge.mergeProgress * 100))パーセント")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }
}
