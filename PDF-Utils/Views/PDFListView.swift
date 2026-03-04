//
//  PDFListView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

/// PDF一覧（左ペイン・サイドバー）
struct PDFListView: View {
    @Environment(PDFWorkspaceViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        List(selection: $vm.merge.selectedItemID) {
            ForEach(viewModel.merge.pdfItems) { item in
                PDFListRowView(item: item)
                    .tag(item.id)
                    .accessibilityAction(named: "上に移動") {
                        if let index = viewModel.merge.pdfItems.firstIndex(where: { $0.id == item.id }), index > 0 {
                            viewModel.moveItems(from: IndexSet(integer: index), to: index - 1)
                        }
                    }
                    .accessibilityAction(named: "下に移動") {
                        if let index = viewModel.merge.pdfItems.firstIndex(where: { $0.id == item.id }), index < viewModel.merge.pdfItems.count - 1 {
                            viewModel.moveItems(from: IndexSet(integer: index), to: index + 2)
                        }
                    }
            }
            .onMove { source, destination in
                viewModel.moveItems(from: source, to: destination)
            }
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        .onDeleteCommand {
            viewModel.removeSelectedItem()
        }
        .accessibilityLabel("PDFファイル一覧")
    }
}
