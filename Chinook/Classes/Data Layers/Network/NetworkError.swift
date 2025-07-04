//
//  NetworkError.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

/// Describes errors that result from network operations.
enum NetworkError: Error {
    /// The URL cannot be constructed as provided.
    case badURL
    /// A non-200 response will throw this error.
    case httpError(statusCode: Int)
    /// An empty response will throw this error.
    case emptyResponse
}
