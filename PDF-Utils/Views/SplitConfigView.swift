//
//  SplitConfigView.swift
//  PDF-Utils
//
//  Created by Soma Kosokabe on 2026/03/03.
//

import SwiftUI
import UniformTypeIdentifiers

/// 分割モードの左ペイン — ファイル情報 + 分割設定UI
struct SplitConfigView: View {
    @Environment(PDFMergeViewModel.self) private var viewModel
    @State private var isSplitFileImporterPresented = false

    var body: some View {
        @Bindable var vm = viewModel

        List {
            // MARK: - ファイル情報セクション
            Section {
                if let source = viewModel.splitSourceItem {
                    sourceFileRow(item: source)
                } else {
                    emptySourceView
                }
            } header: {
                Text("分割元ファイル")
            }

            // MARK: - 分割設定セクション（ファイル選択済みの場合のみ）
            if viewModel.splitSourceItem != nil {
                Section {
                    Picker("分割方法", selection: $vm.splitConfig.method) {
                        Text("ページ範囲指定")
                            .accessibilityLabel("ページ範囲を指定して分割")
                            .tag(SplitMethod.pageRanges)
                        Text("1ページずつ")
                            .accessibilityLabel("全ページを個別ファイルに分割")
                            .tag(SplitMethod.everyPage)
                        Text("偶数/奇数")
                            .accessibilityLabel("偶数ページと奇数ページに分割")
                            .tag(SplitMethod.oddEven)
                    }
                    .pickerStyle(.radioGroup)
                    .disabled(viewModel.isSplitting)
                    .accessibilityLabel("分割方法の選択")
                } header: {
                    Text("分割方法")
                }

                // MARK: - ページ範囲入力（pageRanges 選択時のみ）
                if viewModel.splitConfig.method == .pageRanges {
                    Section {
                        HStack(alignment: .top) {
                            TextField(
                                "1-5, 6-10, 11-\(viewModel.splitSourceItem?.pageCount ?? 1)",
                                text: $vm.splitConfig.rangeText
                            )
                            .textFieldStyle(.roundedBorder)
                            .disabled(viewModel.isSplitting)
                            .accessibilityLabel("分割ページ範囲")
                            .accessibilityHint(validationHint)

                            Text("/ \(viewModel.splitSourceItem?.pageCount ?? 0)ページ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 60, alignment: .trailing)
                        }

                        // バリデーションエラー表示
                        if let errorMessage = validationErrorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                                .transition(.opacity)
                                .accessibilityLabel("エラー: \(errorMessage)")
                        }
                    } header: {
                        Text("ページ範囲")
                    }
                }

                // MARK: - 分割情報サマリー
                splitSummarySection
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    isSplitFileImporterPresented = true
                } label: {
                    Label("ファイル選択", systemImage: "doc.badge.plus")
                }
                .disabled(viewModel.isSplitting)
                .accessibilityLabel("分割対象のPDFファイルを選択")
                .accessibilityHint("ファイル選択ダイアログを開きます")
            }
        }
        .fileImporter(
            isPresented: $isSplitFileImporterPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                viewModel.setSplitSource(url: url)
            case .failure(let error):
                viewModel.alertMessage = error.localizedDescription
            }
        }
        .navigationTitle("分割設定")
    }

    // MARK: - Source File Row

    private func sourceFileRow(item: PDFItem) -> some View {
        HStack(spacing: 10) {
            Image(nsImage: item.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                .accessibilityHidden(true)

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

    // MARK: - Empty Source

    private var emptySourceView: some View {
        VStack(spacing: 8) {
            Image(systemName: "arrow.down.doc")
                .font(.title2)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("PDFファイルをドロップ")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("またはツールバーから選択")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("分割するPDFファイルを選択してください")
    }

    // MARK: - Split Summary

    @ViewBuilder
    private var splitSummarySection: some View {
        if case .success(let groups) = viewModel.splitGroups {
            Section {
                Label(
                    "\(groups.count)ファイルに分割されます",
                    systemImage: "doc.on.doc"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("分割結果")
            }
        }
    }

    // MARK: - Validation

    /// バリデーションエラーメッセージ（nilならエラーなし）
    private var validationErrorMessage: String? {
        guard viewModel.splitConfig.method == .pageRanges else { return nil }
        guard !viewModel.splitConfig.rangeText.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }

        if case .failure(let error) = viewModel.splitGroups {
            return error.localizedDescription
        }
        return nil
    }

    /// アクセシビリティ用のバリデーションヒント
    private var validationHint: String {
        if let error = validationErrorMessage {
            return "エラー: \(error)"
        }
        return "カンマ区切りでページ範囲を入力してください。例: 1-5, 6-10"
    }
}
