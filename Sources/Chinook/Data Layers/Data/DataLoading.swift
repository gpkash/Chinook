//
//  DataLoading.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

public protocol DataLoading {
    /// Makes a request to fetch data asynchronously.
    /// - Parameter endpoint: The endpoint that is involved in fetching the data.
    /// - Returns: A `DataResponse` object on success.
    /// - Throws: An error if the operation fails or is cancelled.
    static func request(_ endpoint: Endpoint) async throws -> DataResponse
    
    /// Cancels any current requests to fetch data.
    static func cancel()
}
