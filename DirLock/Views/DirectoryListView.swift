import SwiftUI
import UniformTypeIdentifiers

struct DirectoryListView: View {
    @ObservedObject var store: DirectoryStore
    var onAddDirectory: () -> Void
    var onClose: () -> Void

    @State private var errorMessage: String? = nil
    @State private var isDroppingOver = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            directoryList
            Divider()
            footer
        }
        .frame(width: 320)
        .onDrop(of: [UTType.fileURL], isTargeted: $isDroppingOver) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url else { return }
                    var isDir: ObjCBool = false
                    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                          isDir.boolValue else { return }
                    DispatchQueue.main.async { store.addDirectory(path: url.path) }
                }
            }
            return true
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor, lineWidth: 2)
                .opacity(isDroppingOver ? 1 : 0)
                .animation(.easeInOut(duration: 0.15), value: isDroppingOver)
        )
        .alert("Operation Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Header

    var header: some View {
        HStack(spacing: 8) {
            Image(systemName: store.hasLockedDirectory ? "lock.fill" : "lock.open")
                .foregroundColor(store.hasLockedDirectory ? .red : .secondary)
            Text("DirLock")
                .font(.headline)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Directory List

    @ViewBuilder
    var directoryList: some View {
        if store.directories.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
                Text("No Directories")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Click 'Add Directory' or drag a folder here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(store.directories) { dir in
                        DirectoryRowView(dir: dir, store: store, onError: { errorMessage = $0 })
                        if dir.id != store.directories.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
            }
            .frame(maxHeight: 280)
        }
    }

    // MARK: - Footer

    var footer: some View {
        VStack(spacing: 8) {
            Button(action: onAddDirectory) {
                Label("Add Directory...", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            HStack(spacing: 8) {
                Button("Lock All") { store.lockAll() }
                    .frame(maxWidth: .infinity)
                    .disabled(store.directories.isEmpty || store.directories.allSatisfy { $0.isLocked })

                Button("Unlock All") { store.unlockAll() }
                    .frame(maxWidth: .infinity)
                    .disabled(store.directories.isEmpty || store.directories.allSatisfy { !$0.isLocked })
            }
            .buttonStyle(.bordered)

            Divider()

            Button(action: { NSApp.terminate(nil) }) {
                Text("Quit DirLock")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
    }
}

// MARK: - Row

struct DirectoryRowView: View {
    let dir: DirectoryItem
    @ObservedObject var store: DirectoryStore
    var onError: (String) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: dir.isLocked ? "lock.fill" : "lock.open")
                .foregroundColor(dir.isLocked ? .red : .green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(dir.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    if !dir.exists {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                Text(dir.displayPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button(dir.isLocked ? "Unlock" : "Lock") {
                do {
                    if dir.isLocked {
                        try store.unlock(id: dir.id)
                    } else {
                        try store.lock(id: dir.id)
                    }
                } catch {
                    onError(error.localizedDescription)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(dir.isLocked ? .green : .red)
            .disabled(!dir.exists)

            Button {
                store.removeDirectory(id: dir.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(dir.isLocked ? Color.red.opacity(0.04) : Color.clear)
    }
}
