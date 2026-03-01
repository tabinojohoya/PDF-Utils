//
//  PDFListRowView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/01.
//

import SwiftUI

/// PDFファイル一覧の各行
struct PDFListRowView: View {
    let item: PDFItem

    var body: some View {
        HStack(spacing: 10) {
            // サムネイル（44×56pt、A4比率）
            Image(nsImage: item.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)

            // ファイル情報
            VStack(alignment: .leading, spacing: 3) {
                Text(item.fileName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(item.fileName)

                Text("\(item.pageCount)ページ · \(item.formattedFileSize)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.fileName)、\(item.pageCount)ページ、\(item.formattedFileSize)")
    }
}
