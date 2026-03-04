# PDF-Utils v1.3.0 Release Notes

## アーキテクチャ改善 & 新機能

PDF-Utils v1.3.0 では、コードベースの大幅なリファクタリングと新機能を追加しました。

---

### ✨ New Features

#### プレビューモード切替
- プレビューペイン右上のセグメントコントロールで singlePage ↔ continuous を切替可能に
- 選択した表示モードはセッション中保持される

#### ファイル間ページ移動
- ページビューでページを別ファイルのセクションにドラッグ&ドロップで移動可能
- 移動後のページは結合結果に正しく反映される

#### キーボードショートカット
- `⌘1` でファイルビューに切替（結合モード内）
- `⌘2` でページビューに切替（結合モード内）

---

### 🔧 Improvements

#### ViewModel 分割（God Object 解消）
- `PDFMergeViewModel` を `PDFWorkspaceViewModel` + `MergeState` + `SplitState` に分割
- 各状態クラスの責務が明確化され、保守性が向上

#### ContentView 分割
- ContentView を 462行 → 121行 に削減
- `ContentView+Toolbar.swift` — ツールバー定義・パネルアクション
- `SuccessBannerView.swift` — 成功バナー（結合・分割共通）
- `MergeStatusBar.swift` — 結合モードステータスバー
- `SplitStatusBar.swift` — 分割モードステータスバー
- `EmptyStateView.swift` — パラメータ化された空状態表示

---

### 📁 Changed Files

#### New Files
- `ViewModels/PDFWorkspaceViewModel.swift` — ワークスペース管理・共通操作
- `ViewModels/MergeState.swift` — 結合モード状態
- `ViewModels/SplitState.swift` — 分割モード状態
- `Views/ContentView+Toolbar.swift` — ツールバー定義
- `Views/SuccessBannerView.swift` — 成功バナー
- `Views/MergeStatusBar.swift` — 結合モードステータスバー
- `Views/SplitStatusBar.swift` — 分割モードステータスバー
- `Views/EmptyStateView.swift` — 空状態表示

#### Modified Files
- `ContentView.swift` — レイアウトのみに簡素化（121行）
- `PDF_UtilsApp.swift` — キーボードショートカット（.commands）追加
- `Views/PDFPreviewView.swift` — PreviewDisplayMode 追加、トグル UI
- `Views/PageGridView.swift` — ファイル間ドロップ対応（.dropDestination）
- `Models/PageItem.swift` — parentID を var に変更（ファイル間移動対応）

#### Removed Files
- `ViewModels/PDFMergeViewModel.swift` — PDFWorkspaceViewModel に置換

---

### 🏗️ Architecture

```
ViewModels/
├── PDFWorkspaceViewModel.swift  # ワークスペース管理・共通操作
├── MergeState.swift             # 結合モード状態（pdfItems, viewMode, ...）
└── SplitState.swift             # 分割モード状態（sourceItem, config, ...）
```

---

### 📋 Version Info

- Bundle ID: `com.soma.PDF-Utils`
- Version: `1.3.0`
- Minimum OS: macOS 26.2+
