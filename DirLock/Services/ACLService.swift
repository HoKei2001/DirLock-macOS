import Foundation

enum ACLError: LocalizedError {
    case commandFailed(String)
    case pathNotFound

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return msg.trimmingCharacters(in: .whitespacesAndNewlines)
        case .pathNotFound:           return "目录不存在"
        }
    }
}

class ACLService {
    static let shared = ACLService()
    private init() {}

    // MARK: - Public API

    /// 锁定目录：设为 000，返回原始权限供解锁时还原
    func lock(path: String) throws -> Int {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ACLError.pathNotFound
        }
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let original = attrs[.posixPermissions] as? Int ?? 0o755
        try runChmod(args: ["000", path])
        return original
    }

    /// 解锁目录：还原原始权限
    func unlock(path: String, originalPermissions: Int?) throws {
        let permsStr = String(format: "%o", originalPermissions ?? 0o755)
        try runChmod(args: [permsStr, path])
    }

    /// 检查目录是否处于锁定状态（权限位全为 0）
    func isLocked(path: String) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let perms = attrs[.posixPermissions] as? Int else { return false }
        return (perms & 0o777) == 0
    }

    // MARK: - Private

    private func runChmod(args: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/chmod")
        process.arguments = args

        let errPipe = Pipe()
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let data = errPipe.fileHandleForReading.readDataToEndOfFile()
            let msg = String(data: data, encoding: .utf8) ?? "未知错误"
            throw ACLError.commandFailed(msg)
        }
    }
}
