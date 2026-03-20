#!/bin/bash
set -e

APP_NAME="DirLock"
BUNDLE_ID="com.heqi.dirlock"
VERSION="1.0"
BUILD_DIR=".build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

# 检测架构
ARCH=$(uname -m)
TARGET="${ARCH}-apple-macosx13.0"
SDK=$(xcrun --show-sdk-path --sdk macosx)

echo "▶ 构建 $APP_NAME (${ARCH})..."

# 清理并创建 bundle 目录结构
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# 编译所有 Swift 源文件
swiftc \
  -sdk "$SDK" \
  -target "$TARGET" \
  -O \
  DirLock/Models/DirectoryItem.swift \
  DirLock/Models/DirectoryStore.swift \
DirLock/Services/ACLService.swift \
  DirLock/Views/AddDirectoryView.swift \
  DirLock/Views/MenuView.swift \
  DirLock/Views/DirectoryListView.swift \
  DirLock/Views/AppPanel.swift \
  DirLock/App/AppDelegate.swift \
  DirLock/App/DirLockApp.swift \
  DirLock/App/main.swift \
  -o "$MACOS_DIR/$APP_NAME"

# 生成图标 icns（用 Python 直接绘制，避免 qlmanage 产生透明角落白边）
swift scripts/gen_icon.swift
ICONSET="/tmp/DirLock.iconset"
rm -rf "$ICONSET" && mkdir "$ICONSET"
ICON_SRC="/tmp/dirlock_icon_final.png"
sips -z 16   16   "$ICON_SRC" --out "$ICONSET/icon_16x16.png"      > /dev/null
sips -z 32   32   "$ICON_SRC" --out "$ICONSET/icon_16x16@2x.png"   > /dev/null
sips -z 32   32   "$ICON_SRC" --out "$ICONSET/icon_32x32.png"      > /dev/null
sips -z 64   64   "$ICON_SRC" --out "$ICONSET/icon_32x32@2x.png"   > /dev/null
sips -z 128  128  "$ICON_SRC" --out "$ICONSET/icon_128x128.png"    > /dev/null
sips -z 256  256  "$ICON_SRC" --out "$ICONSET/icon_128x128@2x.png" > /dev/null
sips -z 256  256  "$ICON_SRC" --out "$ICONSET/icon_256x256.png"    > /dev/null
sips -z 512  512  "$ICON_SRC" --out "$ICONSET/icon_256x256@2x.png" > /dev/null
sips -z 512  512  "$ICON_SRC" --out "$ICONSET/icon_512x512.png"    > /dev/null
sips -z 1024 1024 "$ICON_SRC" --out "$ICONSET/icon_512x512@2x.png" > /dev/null
iconutil -c icns "$ICONSET" -o "$RESOURCES_DIR/AppIcon.icns" > /dev/null

# 处理 Info.plist（替换 Xcode 变量占位符）
sed \
  -e "s|\$(EXECUTABLE_NAME)|$APP_NAME|g" \
  -e "s|\$(PRODUCT_BUNDLE_IDENTIFIER)|$BUNDLE_ID|g" \
  -e "s|\$(PRODUCT_NAME)|$APP_NAME|g" \
  -e "s|\$(PRODUCT_BUNDLE_PACKAGE_TYPE)|APPL|g" \
  -e "s|\$(MACOSX_DEPLOYMENT_TARGET)|13.0|g" \
  -e "s|\$(MARKETING_VERSION)|$VERSION|g" \
  -e "s|\$(CURRENT_PROJECT_VERSION)|1|g" \
  DirLock/Info.plist > "$CONTENTS/Info.plist"

echo "✅ 构建成功：$APP_BUNDLE"
echo ""
echo "运行方式："
echo "  open $APP_BUNDLE"
