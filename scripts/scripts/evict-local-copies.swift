#!/usr/bin/env swift
// Remove local copies of cloud-synced files (Google Drive, iCloud, Dropbox, ...)
// under ~/Library/CloudStorage without deleting them from the cloud.
// `rm` would delete from the cloud too; `brctl evict` only works for iCloud.
//
// Usage: evict-local-copies.swift <file-or-dir>...
import Foundation

let fm = FileManager.default
var evicted = 0, failed = 0

func evict(_ url: URL) {
    do {
        try fm.evictUbiquitousItem(at: url)
        evicted += 1
    } catch {
        failed += 1
        FileHandle.standardError.write("FAIL \(url.path): \(error.localizedDescription)\n".data(using: .utf8)!)
    }
}

let args = CommandLine.arguments.dropFirst()
if args.isEmpty {
    FileHandle.standardError.write("usage: evict-local-copies.swift <file-or-dir>...\n".data(using: .utf8)!)
    exit(64)
}

for arg in args {
    let root = URL(fileURLWithPath: arg)
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: root.path, isDirectory: &isDir) else {
        failed += 1
        FileHandle.standardError.write("MISSING \(arg)\n".data(using: .utf8)!)
        continue
    }
    guard isDir.boolValue else { evict(root); continue }

    let files = fm.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
    while let url = files?.nextObject() as? URL {
        if (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true {
            evict(url)
        }
    }
}

print("evicted=\(evicted) failed=\(failed)")
exit(failed == 0 ? 0 : 1)
