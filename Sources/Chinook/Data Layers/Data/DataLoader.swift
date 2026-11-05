//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

public enum DataLoaderStrategy: Sendable {
    /// Only attempt loading an asset from the cache.
    case diskOnly

    /// Only attempt loading an asset from the network (will save to cache upon success).
    case networkOnly

    /// Try to the load the asset from disk and only hit the network if the asset is not on disk or a disk error occurred.
    case diskWithNetworkFallback
}

enum DataLoaderError: Error {
    /// `.diskOnly` was requested for an asset that isn't cached.
    case notCached
}

/// Loads the bytes behind an `Endpoint`, from the disk cache, the network, or both.
///
/// The loader owns the cache, the fallback rules, a single shared session and a cap on concurrent
/// requests. The only seam is the `DataTransport`, so tests run against a fake.
public struct DataLoader: Sendable {
    static let shared = DataLoader()

    private let transport: DataTransport
    private let cacheDirectory: URL
    private let limiter: RequestLimiter

    init(
        transport: DataTransport = URLSessionTransport(),
        cacheDirectory: URL = DataLoader.defaultCacheDirectory,
        maxConcurrentRequests: Int = 8
    ) {
        self.transport = transport
        self.cacheDirectory = cacheDirectory
        self.limiter = RequestLimiter(limit: maxConcurrentRequests)
    }

    static var defaultCacheDirectory: URL {
        (try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
    }

    static func request(_ endpoint: Endpoint, strategy: DataLoaderStrategy = .diskWithNetworkFallback) async throws -> DataResponse {
        try await shared.request(endpoint, strategy: strategy)
    }

    func request(_ endpoint: Endpoint, strategy: DataLoaderStrategy = .diskWithNetworkFallback) async throws -> DataResponse {
        switch strategy {
        case .diskOnly:
            return try readCache(for: endpoint)

        case .networkOnly:
            return try await fetchAndCache(endpoint)

        case .diskWithNetworkFallback:
            // A missing or unreadable cache entry is not an error here: fall through to the network.
            if let cached = try? readCache(for: endpoint) {
                return cached
            }

            return try await fetchAndCache(endpoint)
        }
    }

    func storageURL(for endpoint: Endpoint) -> URL {
        cacheDirectory.appendingPathComponent(endpoint.cacheRelativePath)
    }

    /// Writes `data` to the cache. Best effort: a cache that can't be written must not fail a load.
    func writeCache(_ data: Data, for endpoint: Endpoint) {
        let fileURL = storageURL(for: endpoint)
        let directoryURL = fileURL.deletingLastPathComponent()
        let fm = FileManager.default

        do {
            // 1) Ensure parent directory exists (and isn't a file)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: directoryURL.path, isDirectory: &isDir), !isDir.boolValue {
                // A file exists where a directory should be (legacy artifact), remove it
                try fm.removeItem(at: directoryURL)
            }

            try fm.createDirectory(at: directoryURL, withIntermediateDirectories: true)

            // 2) If a directory exists at the final file path (also a legacy artifact), remove it
            var isFileDir: ObjCBool = false
            if fm.fileExists(atPath: fileURL.path, isDirectory: &isFileDir), isFileDir.boolValue {
                try fm.removeItem(at: fileURL)
            }

            // 3) Write the file
            try data.write(to: fileURL, options: .atomic)
        }
        catch {
            // Intentionally ignored; see above.
        }
    }
}

private extension DataLoader {
    func readCache(for endpoint: Endpoint) throws -> DataResponse {
        guard let data = try? Data(contentsOf: storageURL(for: endpoint)) else {
            throw DataLoaderError.notCached
        }

        return DataResponse(data: data, source: .disk)
    }

    func fetchAndCache(_ endpoint: Endpoint) async throws -> DataResponse {
        guard let url = endpoint.url else {
            throw NetworkError.badURL
        }

        let (data, response) = try await limiter.withPermit {
            try await transport.data(from: url)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.emptyResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }

        writeCache(data, for: endpoint)

        return DataResponse(data: data, source: .network)
    }
}
