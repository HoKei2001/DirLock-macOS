import AppKit

/// Wrapper around NSOpenPanel for selecting a directory to manage
enum AddDirectoryHelper {

    static func showOpenPanel(completion: @escaping (String?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Add"
        panel.message = "Select a directory for DirLock to manage"

        NSApp.activate(ignoringOtherApps: true)

        if panel.runModal() == .OK {
            completion(panel.url?.path)
        } else {
            completion(nil)
        }
    }
}
