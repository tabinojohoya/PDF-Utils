//
//  AboutView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI

/// 「PDF-Utilsについて」ウィンドウに表示するビュー
struct AboutView: View {
    private let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }()

    private let buildNumber: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }()

    var body: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("PDF-Utils")
                .font(.title.bold())

            Text("バージョン \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("PDFの結合・分割ユーティリティ")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .frame(width: 200)

            Text("© 2026 Soma Kosokabe")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(24)
        .frame(width: 300)
    }
}

#Preview {
    AboutView()
}
