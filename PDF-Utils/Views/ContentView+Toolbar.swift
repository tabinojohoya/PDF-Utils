//
//  ContentView+Toolbar.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

// MARK: - Toolbar & Actions

extension ContentView {

    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        @Bindable var vm = viewModel

        ToolbarItem(placement: .navigation) {
            Picker("モード", selection: $vm.appMode) {
                Label("結合", systemImage: "doc.on.doc").tag(AppMode.merge)
                Label("分割", systemImage: "rectangle.split.2x1").tag(AppMode.split)
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isProcessing)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if viewModel.appMode == .merge && !viewModel.merge.isEmpty {
                Button { showMergeSavePanel() } label: { Label("結合", systemImage: "doc.on.doc.fill") }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.merge.canMerge || viewModel.merge.isMerging)
                    .keyboardShortcut("s", modifiers: .command)
            }
            if viewModel.appMode == .split && viewModel.split.sourceItem != nil {
                Button { showSplitFolderPanel() } label: { Label("分割", systemImage: "scissors") }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.split.canSplit)
                    .keyboardShortcut("s", modifiers: .command)
            }
        }

        ToolbarItemGroup(placement: .automatic) {
            if viewModel.appMode == .merge {
                Picker("表示", selection: $vm.merge.viewMode) {
                    Label("ファイル", systemImage: "list.bullet").tag(MergeState.ViewMode.file)
                    Label("ページ", systemImage: "square.grid.2x2").tag(MergeState.ViewMode.page)
                }
                .pickerStyle(.segmented).disabled(viewModel.merge.isMerging).frame(width: 120)

                Button { isFileImporterPresented = true } label: { Label("ファイル追加", systemImage: "plus") }
                    .keyboardShortcut("o", modifiers: .command).disabled(viewModel.merge.isMerging)

                if !viewModel.merge.isEmpty {
                    Button { viewModel.moveSelectedUp() } label: { Label("上に移動", systemImage: "chevron.up") }
                        .disabled(viewModel.merge.selectedItemID == nil || viewModel.merge.isMerging
                                  || viewModel.merge.pdfItems.first?.id == viewModel.merge.selectedItemID)
                    Button { viewModel.moveSelectedDown() } label: { Label("下に移動", systemImage: "chevron.down") }
                        .disabled(viewModel.merge.selectedItemID == nil || viewModel.merge.isMerging
                                  || viewModel.merge.pdfItems.last?.id == viewModel.merge.selectedItemID)
                    Button { viewModel.removeSelectedItem() } label: { Label("削除", systemImage: "trash") }
                        .disabled(viewModel.merge.selectedItemID == nil || viewModel.merge.isMerging)
                        .keyboardShortcut(.delete, modifiers: .command)
                    Button { viewModel.clearAll() } label: { Label("全クリア", systemImage: "trash.slash") }
                        .disabled(viewModel.merge.isMerging)
                }
            }
        }
    }

    // MARK: - Drop Handling

    func handleDrop(urls: [URL]) -> Bool {
        guard !viewModel.isProcessing else { return false }
        let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
        guard !pdfURLs.isEmpty else { return false }
        switch viewModel.appMode {
        case .merge: viewModel.addFiles(urls: pdfURLs)
        case .split: if let url = pdfURLs.first { viewModel.setSplitSource(url: url) }
        }
        return true
    }

    // MARK: - Panel Actions

    func showMergeSavePanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.pdf]
        panel.nameFieldStringValue = "Merged.pdf"
        panel.title = "結合したPDFの保存先を選択"
        panel.prompt = "保存"
        panel.begin { r in
            guard r == .OK, let url = panel.url else { return }
            Task { await viewModel.performMerge(to: url) }
        }
    }

    func showSplitFolderPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "分割ファイルの保存先フォルダを選択"
        panel.prompt = "選択"
        panel.begin { r in
            guard r == .OK, let url = panel.url else { return }
            Task { await viewModel.performSplit(to: url) }
        }
    }
}
