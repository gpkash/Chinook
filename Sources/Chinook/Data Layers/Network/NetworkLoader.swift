//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

enum NetworkLoader { }

private extension NetworkLoader {
    static let state = NetworkLoaderState()
}

/// Handles network requests.
extension NetworkLoader: DataLoading {
    static func request(_ endpoint: Endpoint) async throws -> DataResponse {
        let urlSession = URLSession(configuration: .default)

        guard let url = endpoint.url else {
            throw NetworkError.badURL
        }

        // Create a task reference for cancellation.
        let (data, _) = try await withTaskCancellationHandler {
            // Handler cannot be async; hop to a Task to call the actor.
            Task { await state.cancel() }
        } operation: {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(Data, HTTPURLResponse), Error>) in
                let task = urlSession.dataTask(with: url) { data, response, error in
                    if let error {
                        Task { await state.set(nil) }
                        continuation.resume(throwing: error)
                        return
                    }

                    guard let httpResponse = response as? HTTPURLResponse else {
                        Task { await state.set(nil) }
                        continuation.resume(throwing: NetworkError.emptyResponse)
                        return
                    }

                    guard (200...299).contains(httpResponse.statusCode) else {
                        Task { await state.set(nil) }
                        continuation.resume(throwing: NetworkError.httpError(statusCode: httpResponse.statusCode))
                        return
                    }

                    guard let data else {
                        Task { await state.set(nil) }
                        continuation.resume(throwing: NetworkError.emptyResponse)
                        return
                    }

                    Task { await state.set(nil) }
                    continuation.resume(returning: (data, httpResponse))
                }

                Task { await state.set(task) }
                task.resume()
            }
        }

        urlSession.finishTasksAndInvalidate()
        return DataResponse(data: data, source: .network)
    }

    static func cancel() {
        Task { await state.cancel() }
    }
}
