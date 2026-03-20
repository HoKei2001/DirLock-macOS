import Foundation
import Combine

class DirectoryStore: ObservableObject {
    static let userDefaultsKey = "com.dirlock.directories"

    @Published var directories: [DirectoryItem] = []

    init() {
        load()
        syncACLStates()
        scanForLockedDirectories()
    }

    // MARK: - Persistence

    func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
              let decoded = try? JSONDecoder().decode([DirectoryItem].self, from: data)
        else { return }
        directories = decoded
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(directories) {
            UserDefaults.standard.set(encoded, forKey: Self.userDefaultsKey)
        }
    }

    // MARK: - Auto-scan for already-locked directories

    func scanForLockedDirectories() {
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser.path
        let scanRoots = [
            home,
            "\(home)/Desktop",
            "\(home)/Documents",
            "\(home)/Downloads",
        ]

        var changed = false
        for root in scanRoots {
            guard let entries = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for entry in entries {
                let path = "\(root)/\(entry)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { continue }
                guard !directories.contains(where: { $0.path == path }) else { continue }
                guard ACLService.shared.isLocked(path: path) else { continue }
                directories.append(DirectoryItem(path: path, isLocked: true))
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - ACL Sync

    func syncACLStates() {
        var changed = false
        for i in directories.indices {
            let actual = ACLService.shared.isLocked(path: directories[i].path)
            if directories[i].isLocked != actual {
                directories[i].isLocked = actual
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - CRUD

    func addDirectory(path: String) {
        guard !directories.contains(where: { $0.path == path }) else { return }
        let isLocked = ACLService.shared.isLocked(path: path)
        directories.append(DirectoryItem(path: path, isLocked: isLocked))
        save()
    }

    func removeDirectory(id: UUID) {
        directories.removeAll { $0.id == id }
        save()
    }

    // MARK: - Lock / Unlock

    func lock(id: UUID) throws {
        guard let index = directories.firstIndex(where: { $0.id == id }) else { return }
        let original = try ACLService.shared.lock(path: directories[index].path)
        directories[index].isLocked = true
        directories[index].originalPermissions = original
        save()
    }

    func unlock(id: UUID) throws {
        guard let index = directories.firstIndex(where: { $0.id == id }) else { return }
        try ACLService.shared.unlock(
            path: directories[index].path,
            originalPermissions: directories[index].originalPermissions
        )
        directories[index].isLocked = false
        directories[index].originalPermissions = nil
        save()
    }

    func lockAll() {
        for i in directories.indices {
            if let original = try? ACLService.shared.lock(path: directories[i].path) {
                directories[i].isLocked = true
                directories[i].originalPermissions = original
            }
        }
        save()
    }

    func unlockAll() {
        for i in directories.indices {
            try? ACLService.shared.unlock(
                path: directories[i].path,
                originalPermissions: directories[i].originalPermissions
            )
            directories[i].isLocked = false
            directories[i].originalPermissions = nil
        }
        save()
    }

    var hasLockedDirectory: Bool {
        directories.contains { $0.isLocked }
    }
}
