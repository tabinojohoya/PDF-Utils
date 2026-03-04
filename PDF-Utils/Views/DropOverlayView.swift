//
//  DropOverlayView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

/// ドラッグ中にウィンドウ全体に表示される磁石エフェクトオーバーレイ
struct DropOverlayView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Frosted glass 背景
            Rectangle()
                .fill(.ultraThinMaterial)

            // 磁石エフェクト: 呼吸するボーダー
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [12, 6])
                )
                .foregroundStyle(.primary.opacity(0.25))
                .padding(24)
                .scaleEffect(isAnimating ? 1.0 : 0.97)

            // メッセージ
            Text("ここに紙をドロップ")
                .font(.title2)
                .fontWeight(.light)
                .foregroundStyle(.primary.opacity(0.5))
                .scaleEffect(isAnimating ? 1.0 : 0.95)
        }
        .transition(
            .opacity.combined(with: .scale(scale: 0.98))
        )
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.7)
            ) {
                isAnimating = true
            }
        }
        .onDisappear { isAnimating = false }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    DropOverlayView()
        .frame(width: 600, height: 400)
}
