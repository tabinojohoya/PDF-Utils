//
//  PDF_UtilsApp.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI
import Sparkle

@main
struct PDF_UtilsApp: App {
    @State private var viewModel = PDFWorkspaceViewModel()

    // Sparkle: SPUStandardUpdaterController はアプリのライフサイクルに合わせて保持
    private let updaterController: SPUStandardUpdaterController

    @State private var checkForUpdatesVM: CheckForUpdatesViewModel

    init() {
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        self.updaterController = controller
        self._checkForUpdatesVM = State(
            initialValue: CheckForUpdatesViewModel(updater: controller.updater)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .defaultSize(width: 960, height: 640)
        .windowResizability(.contentMinSize)
        .commands {
            // 標準の「About」メニューを置き換え
            CommandGroup(replacing: .appInfo) {
                Button("PDF-Utilsについて") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationVersion: appVersion,
                        .version: buildNumber,
                    ])
                }
            }

            // 「アップデートを確認」メニュー
            CommandGroup(after: .appInfo) {
                Button("アップデートを確認…") {
                    checkForUpdatesVM.checkForUpdates()
                }
                .disabled(!checkForUpdatesVM.canCheckForUpdates)
            }

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

    // MARK: - Version Info

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }
}
