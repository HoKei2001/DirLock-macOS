import Foundation

struct DirectoryItem: Identifiable, Codable {
    let id: UUID
    var path: String
    var isLocked: Bool
    var originalPermissions: Int?   // 锁定前保存的权限，解锁时还原

    init(id: UUID = UUID(), path: String, isLocked: Bool = false, originalPermissions: Int? = nil) {
        self.id = id
        self.path = path
        self.isLocked = isLocked
        self.originalPermissions = originalPermissions
    }

    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var displayPath: String {
        path.replacingOccurrences(of: NSHomeDirectory(), with: "~")
    }

    var exists: Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
