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
    @Environment(PDFWorkspaceViewModel.self) var viewModel
    @State var isFileImporterPresented = false

    var body: some View {
        @Bindable var vm = viewModel

        VStack(spacing: 0) {
            contentArea
            if viewModel.appMode == .merge && !viewModel.merge.isEmpty {
                Divider()
                MergeStatusBar()
            }
            if viewModel.appMode == .split && viewModel.split.sourceItem != nil {
                Divider()
                SplitStatusBar()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(.easeInOut(duration: 0.25), value: viewModel.appMode)
        .overlay(alignment: .top) { successBannerOverlay }
        .overlay { if viewModel.isDropTargeted { DropOverlayView() } }
        .dropDestination(for: URL.self) { urls, _ in
            handleDrop(urls: urls)
        } isTargeted: { targeted in
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.isDropTargeted = targeted }
        }
        .toolbar { toolbarContent }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result { viewModel.addFiles(urls: urls) }
            if case .failure(let error) = result { viewModel.currentError = .from(error) }
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
                Text(error.recoverySuggestion.map { "\(error.message)\n\n\($0)" } ?? error.message)
            }
        }
    }

    // MARK: - Content Area

    @ViewBuilder
    private var contentArea: some View {
        switch viewModel.appMode {
        case .merge:
            if viewModel.merge.isEmpty {
                EmptyStateView(
                    icon: "doc.richtext",
                    title: "PDFファイルをここにドロップ",
                    subtitle: "またはファイル追加ボタンで選択"
                )
            } else {
                NavigationSplitView {
                    if viewModel.merge.viewMode == .file { PDFListView() } else { PageGridView() }
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
            NavigationSplitView { SplitConfigView() } detail: { SplitPreviewView() }
        }
    }

    // MARK: - Success Banner

    @ViewBuilder
    private var successBannerOverlay: some View {
        if viewModel.merge.showSuccessBanner {
            SuccessBannerView(
                message: "結合が完了しました",
                accessibilityLabel: "結合完了通知",
                onRevealInFinder: { viewModel.revealInFinder() },
                onDismiss: { withAnimation(.easeOut(duration: 0.3)) { viewModel.merge.showSuccessBanner = false } }
            )
            .padding(.top, 8)
        }
        if viewModel.split.showSuccessBanner {
            SuccessBannerView(
                message: "\(viewModel.split.outputURLs.count)ファイルに分割しました",
                accessibilityLabel: "分割完了通知",
                onRevealInFinder: { viewModel.revealSplitOutputInFinder() },
                onDismiss: { withAnimation(.easeOut(duration: 0.3)) { viewModel.split.showSuccessBanner = false } }
            )
            .padding(.top, 8)
        }
    }

}

#Preview {
    ContentView()
        .environment(PDFWorkspaceViewModel())
}
