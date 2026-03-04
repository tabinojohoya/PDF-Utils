//
//  CheckForUpdatesViewModel.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI
import Sparkle

/// Sparkle の SPUUpdater をラップし、SwiftUI メニューから
/// 「アップデートを確認」ボタンの有効/無効を制御する ViewModel。
@Observable
final class CheckForUpdatesViewModel {

    /// 「アップデートを確認」ボタンが有効かどうか
    var canCheckForUpdates = false

    /// SPUUpdater のインスタンス（外部から注入）
    private let updater: SPUUpdater

    private var observation: NSKeyValueObservation?

    init(updater: SPUUpdater) {
        self.updater = updater
        // KVO で SPUUpdater.canCheckForUpdates を監視
        observation = updater.observe(
            \.canCheckForUpdates,
            options: [.initial, .new]
        ) { [weak self] updater, _ in
            let canCheck = updater.canCheckForUpdates
            Task { @MainActor [weak self] in
                self?.canCheckForUpdates = canCheck
            }
        }
    }

    /// アップデートを確認する
    func checkForUpdates() {
        updater.checkForUpdates()
    }
}
