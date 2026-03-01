//
//  ContentView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(PDFMergeViewModel.self) private var viewModel
    @State private var isFileImporterPresented = false

    var body: some View {
        @Bindable var vm = viewModel

        Group {
            if viewModel.isEmpty {
                emptyStateView
            } else {
                Text("ファイル追加済み: \(viewModel.pdfItems.count)件")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .overlay {
            if viewModel.isDropTargeted {
                DropOverlayView()
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
            guard !pdfURLs.isEmpty else { return false }
            viewModel.addFiles(urls: pdfURLs)
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isDropTargeted = targeted
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !viewModel.isEmpty {
                    Button {
                        // Step 10 で結合処理を接続
                    } label: {
                        Label("結合", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canMerge || viewModel.isMerging)
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("ファイル追加", systemImage: "plus")
                }
                .keyboardShortcut("o", modifiers: .command)

                if !viewModel.isEmpty {
                    Button {
                        viewModel.removeSelectedItem()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .disabled(viewModel.selectedItemID == nil)
                    .keyboardShortcut(.delete, modifiers: .command)

                    Button {
                        viewModel.clearAll()
                    } label: {
                        Label("全クリア", systemImage: "trash.slash")
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                let accessibleURLs = urls.compactMap { url -> URL? in
                    guard url.startAccessingSecurityScopedResource() else { return nil }
                    return url
                }
                viewModel.addFiles(urls: accessibleURLs)
            case .failure(let error):
                viewModel.alertMessage = error.localizedDescription
            }
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { vm.alertMessage != nil },
                set: { if !$0 { vm.alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            if let message = viewModel.alertMessage {
                Text(message)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("PDFファイルをここにドロップ")
                .font(.title2)
                .fontWeight(.medium)

            Text("またはファイル追加ボタンで選択")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .environment(PDFMergeViewModel())
}
