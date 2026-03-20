import AppKit

let app = NSApplication.shared
app.setActivationPolicy(.accessory)  // 不显示 Dock 图标

let delegate = AppDelegate()
app.delegate = delegate
app.run()
