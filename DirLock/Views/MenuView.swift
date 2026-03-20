// MenuView.swift
//
// 菜单 UI 通过 AppDelegate + NSMenuDelegate 实现（见 AppDelegate.swift）。
// 本文件保留，供未来迁移到 SwiftUI MenuBarExtra 时使用。
//
// 当前架构：
//   AppDelegate.menuWillOpen(_:) -> rebuildMenu(_:) -> makeDirectoryMenuItem(for:)
//
// 菜单结构：
//   DirLock（加粗标题）
//   ─────────────────
//   🔒  ~/Desktop/important_files  ▶  [锁定/解锁] [移除]
//   🔓  ~/.ssh                     ▶  [锁定/解锁] [移除]
//   ─────────────────
//   + 添加目录...
//   ─────────────────
//   全部锁定
//   全部解锁
//   ─────────────────
//   退出

import Foundation
