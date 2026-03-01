//
//  PDFListView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

/// PDF一覧（左ペイン・サイドバー）
struct PDFListView: View {
    @Environment(PDFMergeViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel

        List(selection: $vm.selectedItemID) {
            ForEach(viewModel.pdfItems) { item in
                PDFListRowView(item: item)
                    .tag(item.id)
            }
            .onMove { source, destination in
                viewModel.moveItems(from: source, to: destination)
            }
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
        .onDeleteCommand {
            viewModel.removeSelectedItem()
        }
    }
}
