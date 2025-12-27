//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

public enum DataLoaderStrategy {
    /// Only attempt loading an asset from the cache.
    case diskOnly
    /// Only attempt loading an asset from the network (will save to cache upon success).
    case networkOnly
    /// Try to the load the asset from disk and only hit the network if the asset is not on disk or a disk error occurred.
    case diskWithNetworkFallback
}

/// A repository that decides where to load data from (disk and/or network) and manages the disk caching.
public enum DataLoader {
    static func request(_ endpoint: Endpoint, strategy: DataLoaderStrategy = .diskWithNetworkFallback) async throws -> DataResponse {
        switch strategy {
        case .diskOnly:
            // Read only from disk.
            return try await DiskLoader.request(endpoint)

        case .networkOnly:
            // Fetch from network and cache on success.
            let result = try await NetworkLoader.request(endpoint)
            endpoint.cache(result.data)
            return result

        case .diskWithNetworkFallback:
            // Try disk first; if missing or any disk error, fall back to network.
            do {
                return try await DiskLoader.request(endpoint)
            } catch is DiskLoaderError {
                let result = try await NetworkLoader.request(endpoint)
                endpoint.cache(result.data)
                return result
            }
        }
    }
}
