//
//  ContentView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @Environment(PDFMergeViewModel.self) private var viewModel
    @State private var isFileImporterPresented = false

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            Group {
                if viewModel.isEmpty {
                    emptyStateView
                } else {
                    NavigationSplitView {
                        PDFListView()
                    } detail: {
                        PDFPreviewPane(selectedItem: viewModel.selectedItem)
                    }
                }
            }

            // ステータスバー（ファイルがある場合のみ表示）
            if !viewModel.isEmpty {
                Divider()
                statusBar
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .overlay(alignment: .top) {
            // 成功バナー
            if viewModel.showSuccessBanner {
                successBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .overlay {
            if viewModel.isDropTargeted {
                DropOverlayView()
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !viewModel.isMerging else { return false }
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
                        performMerge()
                    } label: {
                        Label("結合", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canMerge || viewModel.isMerging)
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityLabel("PDFを結合")
                    .accessibilityValue("\(viewModel.pdfItems.count)ファイル")
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("ファイル追加", systemImage: "plus")
                }
                .keyboardShortcut("o", modifiers: .command)
                .disabled(viewModel.isMerging)

                if !viewModel.isEmpty {
                    Button {
                        viewModel.removeSelectedItem()
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                    .disabled(viewModel.selectedItemID == nil || viewModel.isMerging)
                    .keyboardShortcut(.delete, modifiers: .command)

                    Button {
                        viewModel.clearAll()
                    } label: {
                        Label("全クリア", systemImage: "trash.slash")
                    }
                    .disabled(viewModel.isMerging)
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

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Label(
                "\(viewModel.pdfItems.count)ファイル · 合計\(viewModel.totalPageCount)ページ",
                systemImage: "doc.text"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            Spacer()

            if viewModel.isMerging {
                ProgressView(value: viewModel.mergeProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 120)
                    .transition(.opacity)
                    .accessibilityLabel("結合の進捗")
                    .accessibilityValue("\(Int(viewModel.mergeProgress * 100))パーセント")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text("結合が完了しました")
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Button("Finderで表示") {
                viewModel.revealInFinder()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    viewModel.showSuccessBanner = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("バナーを閉じる")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("結合完了通知")
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.richtext")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("PDFファイルをここにドロップ")
                .font(.title2)
                .fontWeight(.medium)

            Text("またはファイル追加ボタンで選択")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PDFファイルをドラッグ&ドロップするか、ツールバーのファイル追加ボタンで選択してください")
    }

    // MARK: - Merge Action

    private func performMerge() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.pdf]
        savePanel.nameFieldStringValue = "Merged.pdf"
        savePanel.title = "結合したPDFの保存先を選択"
        savePanel.prompt = "保存"

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            Task {
                await viewModel.merge(to: url)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(PDFMergeViewModel())
}
