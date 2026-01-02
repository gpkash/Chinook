//
//  Endpoint+Caching.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-26.
//

import Foundation

extension Endpoint {
    public var storageURL: URL {
        let cacheDirectory = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        var appendablePath = path.copy() as! String
        appendablePath.remove(at: appendablePath.startIndex)
        appendablePath += ".cache"

        return cacheDirectory.appendingPathComponent(appendablePath)
    }
    
    public func cache(_ data: Data) {
        let fileURL = storageURL
        let directoryURL = fileURL.deletingLastPathComponent()
        let fm = FileManager.default

        do {
            // 1) Ensure parent directory exists (and isn’t a file)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: directoryURL.path, isDirectory: &isDir) {
                if !isDir.boolValue {
                    // A file exists where a directory should be (legacy artifact) — remove it
                    try fm.removeItem(at: directoryURL)
                }
            }

            if !fm.fileExists(atPath: directoryURL.path, isDirectory: &isDir) || !isDir.boolValue {
                try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            }

            // 2) If a directory exists at the final file path (also a legacy artifact), remove it
            var isFileDir: ObjCBool = false
            if fm.fileExists(atPath: fileURL.path, isDirectory: &isFileDir), isFileDir.boolValue {
                try fm.removeItem(at: fileURL)
            }

            // 3) Write the file
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to cache data at \(fileURL.path): \(error)")
        }
    }
}
