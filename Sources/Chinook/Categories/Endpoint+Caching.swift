//
//  Endpoint+Caching.swift
//  Chinook
//

import Foundation

extension Endpoint {
    /// Where this endpoint's cached bytes live, relative to the cache directory.
    var cacheRelativePath: String {
        String(path.dropFirst()) + ".cache"
    }

    public var storageURL: URL {
        DataLoader.shared.storageURL(for: self)
    }

    public func cache(_ data: Data) {
        DataLoader.shared.writeCache(data, for: self)
    }
}
