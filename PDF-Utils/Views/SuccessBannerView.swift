//
//  SuccessBannerView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/04.
//

import SwiftUI

/// 成功バナー（結合・分割共通）
struct SuccessBannerView: View {
    let message: String
    let accessibilityLabel: String
    let onRevealInFinder: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            Text(message)
                .font(.body)
                .fontWeight(.medium)

            Spacer()

            Button("Finderで表示") { onRevealInFinder() }
                .buttonStyle(.bordered)
                .controlSize(.small)

            Button { onDismiss() } label: {
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
        .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.98)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }
}
