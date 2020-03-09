//
//  DataLoading.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation

public protocol DataLoading {
    /// Makes a request to fetch data. Returns the progress associated to this operation.
    /// - Parameters:
    ///   - endpoint: The endpoint that is involved in fetching the data.
    ///   - completion: Called once the request has either fulfilled or failed.
    func request(_ endpoint: Endpoint, completion: @escaping (Result<DataResponse, Error>) -> Void) -> Progress
    
    /// Cancels any current requests to fetch data.
    func cancel()
}
