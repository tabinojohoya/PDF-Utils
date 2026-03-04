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
    @Environment(PDFWorkspaceViewModel.self) private var viewModel
    @State private var isFileImporterPresented = false

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            Group {
                switch viewModel.appMode {
                case .merge:
                    if viewModel.merge.isEmpty {
                        emptyStateView
                    } else {
                        NavigationSplitView {
                            if viewModel.merge.viewMode == .file {
                                PDFListView()
                            } else {
                                PageGridView()
                            }
                        } detail: {
                            if viewModel.merge.isShowingMergedPreview,
                               let url = viewModel.merge.mergedDocumentURL {
                                MergedPreviewView(url: url)
                            } else {
                                PDFPreviewPane(selectedItem: viewModel.merge.selectedItem)
                            }
                        }
                    }
                case .split:
                    NavigationSplitView {
                        SplitConfigView()
                    } detail: {
                        SplitPreviewView()
                    }
                }
            }

            // ステータスバー
            if viewModel.appMode == .merge && !viewModel.merge.isEmpty {
                Divider()
                mergeStatusBar
            }
            if viewModel.appMode == .split && viewModel.split.sourceItem != nil {
                Divider()
                splitStatusBar
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(.easeInOut(duration: 0.25), value: viewModel.appMode)
        .overlay(alignment: .top) {
            // 成功バナー
            if viewModel.merge.showSuccessBanner {
                mergeSuccessBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
            if viewModel.split.showSuccessBanner {
                splitSuccessBanner
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
            guard !viewModel.isProcessing else { return false }
            let pdfURLs = urls.filter { $0.pathExtension.lowercased() == "pdf" }
            guard !pdfURLs.isEmpty else { return false }

            switch viewModel.appMode {
            case .merge:
                viewModel.addFiles(urls: pdfURLs)
            case .split:
                // 分割モードでは先頭1ファイルのみ採用
                if let url = pdfURLs.first {
                    viewModel.setSplitSource(url: url)
                }
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.isDropTargeted = targeted
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Picker("モード", selection: $vm.appMode) {
                    Label("結合", systemImage: "doc.on.doc")
                        .tag(AppMode.merge)
                    Label("分割", systemImage: "rectangle.split.2x1")
                        .tag(AppMode.split)
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isProcessing)
                .accessibilityLabel("動作モード切替")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.appMode == .merge && !viewModel.merge.isEmpty {
                    Button {
                        performMerge()
                    } label: {
                        Label("結合", systemImage: "doc.on.doc.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.merge.canMerge || viewModel.merge.isMerging)
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityLabel("PDFを結合")
                    .accessibilityValue("\(viewModel.merge.pdfItems.count)ファイル")
                }

                if viewModel.appMode == .split && viewModel.split.sourceItem != nil {
                    Button {
                        performSplit()
                    } label: {
                        Label("分割", systemImage: "scissors")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.split.canSplit)
                    .keyboardShortcut("s", modifiers: .command)
                    .accessibilityLabel("PDFを分割")
                    .accessibilityValue(splitAccessibilityValue)
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                if viewModel.appMode == .merge {
                    // 表示モード切替（ファイル / ページ）
                    Picker("表示", selection: $vm.merge.viewMode) {
                        Label("ファイル", systemImage: "list.bullet")
                            .tag(MergeState.ViewMode.file)
                        Label("ページ", systemImage: "square.grid.2x2")
                            .tag(MergeState.ViewMode.page)
                    }
                    .pickerStyle(.segmented)
                    .disabled(viewModel.merge.isMerging)
                    .accessibilityLabel("表示モード切替")
                    .frame(width: 120)

                    Button {
                        isFileImporterPresented = true
                    } label: {
                        Label("ファイル追加", systemImage: "plus")
                    }
                    .keyboardShortcut("o", modifiers: .command)
                    .disabled(viewModel.merge.isMerging)

                    if !viewModel.merge.isEmpty {
                        Button {
                            viewModel.moveSelectedUp()
                        } label: {
                            Label("上に移動", systemImage: "chevron.up")
                        }
                        .disabled(viewModel.merge.selectedItemID == nil || viewModel.merge.isMerging || viewModel.merge.pdfItems.first?.id == viewModel.merge.selectedItemID)
                        .accessibilityLabel("選択ファイルを上に移動")

                        Button {
                            viewModel.moveSelectedDown()
                        } label: {
                            Label("下に移動", systemImage: "chevron.down")
                        }
                        .disabled(viewModel.merge.selectedItemID == nil || viewModel.merge.isMerging || viewModel.merge.pdfItems.last?.id == viewModel.merge.selectedItemID)
                        .accessibilityLabel("選択ファイルを下に移動")

                        Button {
                            viewModel.removeSelectedItem()
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                        .disabled(viewModel.merge.selectedItemID == nil || viewModel.merge.isMerging)
                        .keyboardShortcut(.delete, modifiers: .command)

                        Button {
                            viewModel.clearAll()
                        } label: {
                            Label("全クリア", systemImage: "trash.slash")
                        }
                        .disabled(viewModel.merge.isMerging)
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
                viewModel.addFiles(urls: urls)
            case .failure(let error):
                viewModel.currentError = .from(error)
            }
        }
        .alert(
            viewModel.currentError?.title ?? "エラー",
            isPresented: Binding(
                get: { vm.currentError != nil },
                set: { if !$0 { vm.currentError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.currentError {
                if let suggestion = error.recoverySuggestion {
                    Text("\(error.message)\n\n\(suggestion)")
                } else {
                    Text(error.message)
                }
            }
        }
    }

    // MARK: - Split Accessibility

    private var splitAccessibilityValue: String {
        if case .success(let groups) = viewModel.split.splitGroups {
            return "\(groups.count)ファイルに分割"
        }
        return "分割不可"
    }

    // MARK: - Status Text

    private var statusText: String {
        "\(viewModel.merge.pdfItems.count)ファイル · 合計\(viewModel.merge.includedPageCount)ページ"
    }

    // MARK: - Merge Status Bar

    private var mergeStatusBar: some View {
        HStack {
            Label(
                statusText,
                systemImage: "doc.text"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            // 0ページのファイル警告
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

    // MARK: - Split Status Bar

    private var splitStatusBar: some View {
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

    // MARK: - Merge Success Banner

    private var mergeSuccessBanner: some View {
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
                    viewModel.merge.showSuccessBanner = false
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

    // MARK: - Split Success Banner

    private var splitSuccessBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text("\(viewModel.split.outputURLs.count)ファイルに分割しました")
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Button("Finderで表示") {
                viewModel.revealSplitOutputInFinder()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                withAnimation(.easeOut(duration: 0.3)) {
                    viewModel.split.showSuccessBanner = false
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
        .accessibilityLabel("分割完了通知")
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
                await viewModel.performMerge(to: url)
            }
        }
    }

    // MARK: - Split Action

    private func performSplit() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "分割ファイルの保存先フォルダを選択"
        openPanel.prompt = "選択"

        openPanel.begin { response in
            guard response == .OK, let url = openPanel.url else { return }
            Task {
                await viewModel.performSplit(to: url)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(PDFWorkspaceViewModel())
}
