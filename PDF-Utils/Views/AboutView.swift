//
//  AboutView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI

/// 「Assembleについて」ウィンドウに表示するビュー
struct AboutView: View {
    private let appVersion: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }()

    private let buildNumber: String = {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
    }()

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 112, height: 112)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)

            VStack(spacing: 4) {
                Text("Assemble")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .tracking(0.5)

                Text("紙束を、ひとつに。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("バージョン \(appVersion) (\(buildNumber))")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Divider()
                .frame(width: 180)

            Text("© 2026 Assemble Labs")
                .font(.caption2)
                .foregroundStyle(.quaternary)
        }
        .padding(32)
        .frame(width: 300)
    }
}

#Preview {
    AboutView()
}
