import AppKit

/// 点击菜单栏图标弹出的浮动面板
class AppPanel: NSPanel {

    override var canBecomeKey: Bool { true }

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .popUpMenu
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isReleasedWhenClosed = false
        backgroundColor = .windowBackgroundColor
    }

    /// 定位到菜单栏按钮正下方
    func positionBelow(button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let buttonFrame = buttonWindow.convertToScreen(button.bounds)

        let x = buttonFrame.midX - frame.width / 2
        let y = buttonFrame.minY - frame.height - 4

        let screenWidth = NSScreen.main?.frame.width ?? 1440
        let clampedX = min(max(x, 8), screenWidth - frame.width - 8)

        setFrameOrigin(NSPoint(x: clampedX, y: y))
    }
}
