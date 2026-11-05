//
//  BookCloud.swift
//  transaction
//

import Foundation

/// One consistent copy of ledger.sqlite in the iPhone's iCloud Drive container.
enum BookCloud {
    struct Stamp: Sendable {
        var signedIn: Bool
        var savedAt: Date?
    }

    nonisolated static func stamp() async -> Stamp {
        await Task.detached(priority: .utility) {
            guard let file = documentURL() else {
                return Stamp(signedIn: false, savedAt: nil)
            }
            let values = try? FileManager.default.attributesOfItem(atPath: file.path)
            return Stamp(signedIn: true, savedAt: values?[.modificationDate] as? Date)
        }.value
    }

    nonisolated static func write(_ source: URL) -> Date? {
        guard let dest = documentURL() else { return nil }
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var when: Date?
        coordinator.coordinate(writingItemAt: dest, options: .forReplacing, error: &coordinationError) { url in
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                try FileManager.default.copyItem(at: source, to: url)
                when = Date()
            } catch {
                when = nil
            }
        }
        if coordinationError != nil { return nil }
        return when
    }

    nonisolated static func read(into dest: URL) -> Bool {
        guard let source = documentURL(), FileManager.default.fileExists(atPath: source.path) else { return false }
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var copied = false
        coordinator.coordinate(readingItemAt: source, options: [], error: &coordinationError) { url in
            do {
                if FileManager.default.fileExists(atPath: dest.path) {
                    try FileManager.default.removeItem(at: dest)
                }
                try FileManager.default.copyItem(at: url, to: dest)
                copied = true
            } catch {
                copied = false
            }
        }
        return coordinationError == nil && copied
    }

    nonisolated private static func containerID() -> String? {
        guard let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty else { return nil }
        return "iCloud.\(bundleID)"
    }

    nonisolated private static func documentURL() -> URL? {
        guard let root = FileManager.default.url(forUbiquityContainerIdentifier: containerID()) else { return nil }
        let folder = root.appendingPathComponent("Documents", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("ledger.sqlite")
    }
}
