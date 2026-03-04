#!/bin/bash
# =============================================================================
# release.sh — PDF-Utils リリース自動化スクリプト
#
# 使い方:
#   ./scripts/release.sh 1.4.0
#
# 処理内容:
#   1. project.pbxproj の MARKETING_VERSION と CURRENT_PROJECT_VERSION を更新
#   2. Release ビルドを実行
#   3. DMG を作成
#   4. Sparkle の EdDSA 署名を付与
#   5. appcast.xml を生成
#   6. git tag を作成
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# 引数チェック
# ---------------------------------------------------------------------------
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <version>  (例: 1.4.0)"
    exit 1
fi

VERSION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PBXPROJ="$PROJECT_DIR/PDF-Utils.xcodeproj/project.pbxproj"
APP_NAME="PDF-Utils"
SCHEME="PDF-Utils"
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
BUILD_DIR="$PROJECT_DIR/build"
DMG_STAGING="$BUILD_DIR/dmg_staging"
DERIVED_DATA="$BUILD_DIR/DerivedData"
APPCAST_DIR="$PROJECT_DIR/docs"    # GitHub Pages 用
APPCAST_FILE="$APPCAST_DIR/appcast.xml"

# Sparkle の generate_appcast / sign_update のパス
# SPM キャッシュから Sparkle のツールを探す
SPARKLE_BIN=""
for dir in ~/Library/Developer/Xcode/DerivedData/*/SourcePackages/artifacts/sparkle/Sparkle/bin; do
    if [[ -d "$dir" ]]; then
        SPARKLE_BIN="$dir"
        break
    fi
done

if [[ -z "$SPARKLE_BIN" ]]; then
    echo "⚠️  Sparkle のバイナリツールが見つかりません。"
    echo "   Xcode で一度ビルドするか、Sparkle を手動ダウンロードしてください。"
    echo "   https://github.com/sparkle-project/Sparkle/releases"
    echo ""
    echo "   手動設定: export SPARKLE_BIN=/path/to/Sparkle/bin"
    exit 1
fi

SIGN_UPDATE="$SPARKLE_BIN/sign_update"
GENERATE_APPCAST="$SPARKLE_BIN/generate_appcast"

echo "============================================"
echo "  PDF-Utils Release v${VERSION}"
echo "============================================"

# ---------------------------------------------------------------------------
# 1. バージョン番号の更新
# ---------------------------------------------------------------------------
echo ""
echo "📝 バージョン番号を更新中..."

# MARKETING_VERSION を更新
sed -i '' "s/MARKETING_VERSION = [^;]*/MARKETING_VERSION = ${VERSION}/" "$PBXPROJ"

# CURRENT_PROJECT_VERSION をインクリメント
CURRENT_BUILD=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/.*= \([0-9]*\).*/\1/')
NEW_BUILD=$((CURRENT_BUILD + 1))
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*/CURRENT_PROJECT_VERSION = ${NEW_BUILD}/g" "$PBXPROJ"

echo "   MARKETING_VERSION: ${VERSION}"
echo "   CURRENT_PROJECT_VERSION: ${NEW_BUILD}"

# ---------------------------------------------------------------------------
# 2. Release ビルド
# ---------------------------------------------------------------------------
echo ""
echo "🔨 Release ビルド中..."

xcodebuild -project "$PROJECT_DIR/PDF-Utils.xcodeproj" \
    -scheme "$SCHEME" \
    -destination 'platform=macOS' \
    -configuration Release \
    -derivedDataPath "$DERIVED_DATA" \
    clean build 2>&1 | tail -5

BUILT_APP="$DERIVED_DATA/Build/Products/Release/${APP_NAME}.app"
if [[ ! -d "$BUILT_APP" ]]; then
    echo "❌ ビルド失敗: ${BUILT_APP} が見つかりません"
    exit 1
fi

echo "   ✅ ビルド成功"

# ---------------------------------------------------------------------------
# 3. DMG 作成
# ---------------------------------------------------------------------------
echo ""
echo "📦 DMG 作成中..."

mkdir -p "$DMG_STAGING"
rm -rf "$DMG_STAGING/${APP_NAME}.app"
cp -R "$BUILT_APP" "$DMG_STAGING/"

# Applications シンボリックリンク
if [[ ! -L "$DMG_STAGING/Applications" ]]; then
    ln -s /Applications "$DMG_STAGING/Applications"
fi

DMG_PATH="$BUILD_DIR/$DMG_NAME"
rm -f "$DMG_PATH"

hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH" 2>&1 | tail -2

echo "   ✅ ${DMG_NAME} 作成完了"

# ---------------------------------------------------------------------------
# 4. Sparkle 署名 & appcast 生成
# ---------------------------------------------------------------------------
echo ""
echo "🔐 Sparkle appcast 生成中..."

mkdir -p "$APPCAST_DIR"

# generate_appcast は DMG があるディレクトリを指定する
# 鍵がなければ自動生成される
"$GENERATE_APPCAST" "$BUILD_DIR" \
    --download-url-prefix "https://github.com/tabinojohoya/PDF-Utils/releases/download/v${VERSION}/" \
    -o "$APPCAST_FILE" 2>&1 || {
    echo "⚠️  generate_appcast 実行に失敗しました。"
    echo "   EdDSA 鍵が未設定の場合: ${SIGN_UPDATE} --generate-keys を実行してください。"
    exit 1
}

echo "   ✅ appcast.xml 生成完了"

# ---------------------------------------------------------------------------
# 5. Git: コミット & タグ
# ---------------------------------------------------------------------------
echo ""
echo "🏷️  Git コミット & タグ..."

cd "$PROJECT_DIR"
git add -A
git commit -m "release: v${VERSION}"
git tag -a "v${VERSION}" -m "Release v${VERSION}"

echo "   ✅ タグ v${VERSION} を作成"

# ---------------------------------------------------------------------------
# 完了
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo "  ✅ Release v${VERSION} 完了!"
echo "============================================"
echo ""
echo "次のステップ:"
echo "  1. git push origin main --tags"
echo "  2. GitHub Releases に ${DMG_NAME} をアップロード"
echo "     → ${BUILD_DIR}/${DMG_NAME}"
echo "  3. GitHub Pages を有効にして docs/ フォルダを公開"
echo "     → appcast.xml が https://tabinojohoya.github.io/PDF-Utils/appcast.xml で配信されます"
echo ""
