//
//  EmptyStateView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI

/// 空状態ビュー（結合・分割共通、メッセージ引数化）
///
/// `icon` を `nil` にするとテキストのみの静かな空状態になる。
struct EmptyStateView: View {
    let icon: String?
    let title: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Text(title)
                .font(icon == nil ? .title : .title2)
                .fontWeight(icon == nil ? .light : .medium)
                .foregroundStyle(icon == nil ? .secondary : .primary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)\(subtitle.map { "。\($0)" } ?? "")")
    }
}
