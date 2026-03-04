//
//  SplitStatusBar.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI

/// 分割モードのステータスバー
struct SplitStatusBar: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel

    var body: some View {
        HStack {
            if let source = viewModel.split.sourceItem {
                Label(
                    "\(source.fileName) · \(source.pageCount)ページ",
                    systemImage: "doc.text"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                if case .success(let groups) = viewModel.split.splitGroups {
                    Text("→ \(groups.count)ファイル")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if viewModel.split.isSplitting {
                ProgressView(value: viewModel.split.splitProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 120)
                    .transition(.opacity)
                    .accessibilityLabel("分割の進捗")
                    .accessibilityValue("\(Int(viewModel.split.splitProgress * 100))パーセント")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }
}
