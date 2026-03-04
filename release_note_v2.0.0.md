# Assemble v2.0.0 Release Notes

## 「Assemble」— 紙束を、ひとつに。

v2.0.0 は PDF-Utils からの全面リブランドです。名前・UI・アニメーション・メッセージをすべて刷新し、「Assemble」として生まれ変わりました。

---

### ✨ ブランドリニューアル

- **新プロダクト名**: PDF-Utils → **Assemble**
- **新タグライン**: 「紙束を、ひとつに。」
- **About 画面**: Assemble ブランドに完全刷新。アイコン・ロゴタイプ・タグライン・バージョン情報のミニマルな構成
- **メニュー**: 「Assembleについて」に変更
- **コピーライト**: © 2026 Assemble Labs

### 🎨 デザイン刷新

#### Empty State の再設計
- 「ここに、紙を。」— アイコンなし、テキストのみの静かな空状態
- 大きく軽いウェイトのフォントで、空白の威厳を表現

#### ドロップゾーンの全面刷新
- **Frosted glass 背景**: `.ultraThinMaterial` による透過エフェクト
- **磁石アニメーション**: Spring Animation によるバウンスエフェクト。ドラッグ進入時にボーダーとテキストが `scaleEffect` で 0.97 → 1.0 にスプリング
- **新メッセージ**: 「ここに紙をドロップ」（軽いウェイト、控えめな存在感）

#### Success Banner のメッセージ
- 結合完了 →「**束ねました。**」
- 分割完了 →「**ほどきました。**」
- Scale エフェクト付きトランジションを追加

### ⚡ アニメーションの全面 Spring 化

アプリ内のすべてのアニメーションを `easeInOut` / `easeOut` から `.spring(response:dampingFraction:)` に置換しました。UI に「生きている」感触を与え、すべての動きに物理的な自然さを持たせています。

対象箇所:
- モード切替アニメーション
- ドロップターゲット表示/非表示
- ファイル追加・削除・クリア
- ページ選択トグル
- 出力プレビュー表示/非表示
- Success Banner 表示/自動非表示
- PDF プレビュー切替

---

### 📁 Changed Files

| ファイル | 変更内容 |
|----------|----------|
| `Views/AboutView.swift` | Assemble ブランドに全面刷新 |
| `Views/DropOverlayView.swift` | Frosted glass + Spring Animation に再実装 |
| `Views/EmptyStateView.swift` | `icon` / `subtitle` をオプショナル化、テキストのみ表示に対応 |
| `Views/SuccessBannerView.swift` | Scale 付きトランジション追加 |
| `ContentView.swift` | Empty State・Banner メッセージ変更、全アニメーション spring 化 |
| `PDF_UtilsApp.swift` | メニュー文字列を「Assembleについて」に変更 |
| `ViewModels/PDFWorkspaceViewModel.swift` | 全アニメーション spring 化 |
| `Views/PDFPreviewView.swift` | プレビュー切替アニメーション spring 化 |

---

### 📋 Version Info

- Bundle ID: `com.soma.PDF-Utils`（※ コード識別子は v2.0.0 では変更なし）
- Version: `2.0.0`
- Minimum OS: macOS 26.2+

---

### 🔮 v2.1.0 予定

- パスワード保護 PDF の読み込み・結合対応
- アプリアイコン再デザイン
