//
//  AppError.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/03.
//

import Foundation

/// アプリ全体のエラーを表す構造化型
struct AppError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let recoverySuggestion: String?
    let style: Style

    enum Style {
        case warning   // 続行可能（重複ファイル等）
        case error     // 操作失敗
    }
}

// MARK: - Factory Methods

extension AppError {

    /// PDFItemError からの変換
    static func from(_ error: PDFItemError) -> AppError {
        switch error {
        case .notReadable(let url):
            return AppError(
                title: "ファイルを開けません",
                message: "\(url.lastPathComponent) はPDFとして読み込めませんでした。",
                recoverySuggestion: "ファイルが破損していないか確認してください。別のPDFビューアで開けるか試してみてください。",
                style: .error
            )
        case .passwordProtected(let url):
            return AppError(
                title: "パスワード保護",
                message: "\(url.lastPathComponent) はパスワードで保護されているため使用できません。",
                recoverySuggestion: "Adobe Acrobat等でパスワードを解除してから再度追加してください。",
                style: .error
            )
        }
    }

    /// PDFMergeError からの変換
    static func from(_ error: PDFMergeError) -> AppError {
        switch error {
        case .fileNotReadable(let url):
            return AppError(
                title: "ファイルを開けません",
                message: "\(url.lastPathComponent) の読み込みに失敗しました。",
                recoverySuggestion: "ファイルが移動または削除されていないか確認してください。",
                style: .error
            )
        case .passwordProtected(let url):
            return AppError(
                title: "パスワード保護",
                message: "\(url.lastPathComponent) はパスワードで保護されています。",
                recoverySuggestion: "パスワードを解除してから再度お試しください。",
                style: .error
            )
        case .writeFailed(let url):
            return AppError(
                title: "保存できませんでした",
                message: "\(url.lastPathComponent) を保存できませんでした。",
                recoverySuggestion: "保存先のディスク容量と書き込み権限を確認してください。",
                style: .error
            )
        case .noFiles:
            return AppError(
                title: "結合できません",
                message: "結合するファイルがありません。",
                recoverySuggestion: "PDFファイルを追加してから結合を実行してください。",
                style: .error
            )
        }
    }

    /// PDFSplitError からの変換
    static func from(_ error: PDFSplitError) -> AppError {
        switch error {
        case .fileNotReadable(let url):
            return AppError(
                title: "ファイルを開けません",
                message: "\(url.lastPathComponent) の読み込みに失敗しました。",
                recoverySuggestion: "ファイルが移動または削除されていないか確認してください。",
                style: .error
            )
        case .passwordProtected(let url):
            return AppError(
                title: "パスワード保護",
                message: "\(url.lastPathComponent) はパスワードで保護されています。",
                recoverySuggestion: "パスワードを解除してから再度お試しください。",
                style: .error
            )
        case .writeFailed(let url):
            return AppError(
                title: "保存できませんでした",
                message: "\(url.lastPathComponent) を保存できませんでした。",
                recoverySuggestion: "保存先のディスク容量と書き込み権限を確認してください。",
                style: .error
            )
        case .noGroups:
            return AppError(
                title: "分割できません",
                message: "分割するグループが指定されていません。",
                recoverySuggestion: "分割方法を設定してから実行してください。",
                style: .error
            )
        }
    }

    /// 重複ファイルの通知
    static func duplicateFiles(count: Int) -> AppError {
        AppError(
            title: "追加済みのファイル",
            message: "選択された\(count)ファイルはすべて追加済みです。",
            recoverySuggestion: nil,
            style: .warning
        )
    }

    /// アクセス拒否
    static func accessDenied(fileName: String) -> AppError {
        AppError(
            title: "アクセスが拒否されました",
            message: "\(fileName) へのアクセスが拒否されました。",
            recoverySuggestion: "アプリにファイルへのアクセス権限があるか確認してください。",
            style: .error
        )
    }

    /// 結合対象ページなし
    static var noIncludedPages: AppError {
        AppError(
            title: "結合できません",
            message: "結合対象のページがありません。",
            recoverySuggestion: "ページのチェックボックスで結合対象を選択してください。",
            style: .error
        )
    }

    /// 汎用エラー（型不明の Error から）
    static func from(_ error: Error) -> AppError {
        if let itemError = error as? PDFItemError {
            return from(itemError)
        } else if let mergeError = error as? PDFMergeError {
            return from(mergeError)
        } else if let splitError = error as? PDFSplitError {
            return from(splitError)
        }
        return AppError(
            title: "エラー",
            message: error.localizedDescription,
            recoverySuggestion: nil,
            style: .error
        )
    }
}
