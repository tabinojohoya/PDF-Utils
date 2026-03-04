//
//  SecurityScopeManager.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/03.
//

import Foundation

/// セキュリティスコープ付きURLのライフサイクルを一元管理する
final class SecurityScopeManager {

    /// 現在アクセス中のURL集合
    private var accessingURLs: Set<URL> = []

    /// セキュリティスコープアクセスを開始する
    /// - Parameter url: アクセス対象のURL
    /// - Returns: アクセス成功なら true
    @discardableResult
    func startAccessing(_ url: URL) -> Bool {
        guard !accessingURLs.contains(url) else { return true }  // 二重開始防止
        guard url.startAccessingSecurityScopedResource() else { return false }
        accessingURLs.insert(url)
        return true
    }

    /// セキュリティスコープアクセスを終了する
    /// - Parameter url: 解放対象のURL
    func stopAccessing(_ url: URL) {
        guard accessingURLs.contains(url) else { return }
        url.stopAccessingSecurityScopedResource()
        accessingURLs.remove(url)
    }

    /// 全てのアクセスを終了する（アプリ終了時など）
    func stopAll() {
        for url in accessingURLs {
            url.stopAccessingSecurityScopedResource()
        }
        accessingURLs.removeAll()
    }

    deinit {
        stopAll()
    }
}
