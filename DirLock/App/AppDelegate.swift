import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    let store = DirectoryStore()

    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        showMainWindow()
    }

    // 点击 Dock 图标时重新打开窗口
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { showMainWindow() }
        return true
    }

    // MARK: - 主窗口

    func showMainWindow() {
        if let w = mainWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = DirectoryListView(
            store: store,
            onAddDirectory: { [weak self] in self?.addDirectory() },
            onClose: { [weak self] in self?.mainWindow?.orderOut(nil) }
        )

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DirLock"
        window.center()
        window.contentView = NSHostingView(rootView: contentView)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow = window
    }

    // MARK: - 菜单栏图标（如果空间够用）

    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            let symbol = store.hasLockedDirectory ? "lock.fill" : "lock.open"
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "DirLock")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    func updateStatusIcon() {
        let symbol = store.hasLockedDirectory ? "lock.fill" : "lock.open"
        statusItem?.button?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "DirLock")
    }

    // MARK: - Popover（菜单栏图标点击）

    func setupPopover() {
        let contentView = DirectoryListView(
            store: store,
            onAddDirectory: { [weak self] in self?.addDirectory() },
            onClose: { [weak self] in self?.popover?.performClose(nil) }
        )
        let p = NSPopover()
        p.contentSize = NSSize(width: 320, height: 420)
        p.behavior = .transient
        p.animates = true
        p.contentViewController = NSHostingController(rootView: contentView)
        self.popover = p
    }

    @objc func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            store.syncACLStates()
            updateStatusIcon()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    // MARK: - 添加目录

    func addDirectory() {
        AddDirectoryHelper.showOpenPanel { [weak self] path in
            guard let self, let path else { return }
            self.store.addDirectory(path: path)
            self.updateStatusIcon()
        }
    }
}
