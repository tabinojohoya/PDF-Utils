//
//  PDF_UtilsApp.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

@main
struct PDF_UtilsApp: App {
    @State private var viewModel = PDFWorkspaceViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .defaultSize(width: 960, height: 640)
        .windowResizability(.contentMinSize)
        .commands {
            // 表示モード切替: ⌘1 → ファイルビュー, ⌘2 → ページビュー
            CommandGroup(after: .toolbar) {
                Button("ファイルビュー") {
                    viewModel.merge.viewMode = .file
                }
                .keyboardShortcut("1", modifiers: .command)
                .disabled(viewModel.appMode != .merge || viewModel.merge.isMerging)

                Button("ページビュー") {
                    viewModel.merge.viewMode = .page
                }
                .keyboardShortcut("2", modifiers: .command)
                .disabled(viewModel.appMode != .merge || viewModel.merge.isMerging)
            }
        }
    }
}
