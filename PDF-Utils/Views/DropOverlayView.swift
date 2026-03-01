//
//  DropOverlayView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

/// ドラッグ中にウィンドウ全体に表示されるオーバーレイ
struct DropOverlayView: View {
    var body: some View {
        ZStack {
            // 穏やかなブルー背景
            Color.blue.opacity(0.08)

            // 破線ボーダー + コンテンツ
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundStyle(.blue.opacity(0.4))
                .padding(20)

            VStack(spacing: 12) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue.opacity(0.6))

                Text("ドロップしてPDFを追加")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue.opacity(0.8))
            }
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }
}

#Preview {
    DropOverlayView()
        .frame(width: 600, height: 400)
}
