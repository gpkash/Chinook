//
//  DiskLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

/// Describes an error when loading assets from disk.
///
/// - missingAsset: The asset is not found on disk.
enum DiskLoaderError: Error {
    case missingAsset
}

/// Handles disk requests.
enum DiskLoader { }

private extension DiskLoader {
    static let state = DiskLoaderState()
}

extension DiskLoader: DataLoading {
    static func request(_ endpoint: Endpoint) async throws -> DataResponse {
        // Create a child Task so we can cancel via `cancel()`.
        let task = Task<DataResponse, Error> {
            try Task.checkCancellation()
            let data = try Data(contentsOf: endpoint.storageURL)
            try Task.checkCancellation()
            return DataResponse(data: data, source: .disk)
        }

        // Keep a reference for cancellation in an actor-isolated state.
        await state.set(task)
        defer { Task { await state.set(nil) } }

        return try await task.value
    }

    static func cancel() {
        Task { await state.cancel() }
    }
}
