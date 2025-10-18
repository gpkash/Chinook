//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

/// Handles network requests.
final class NetworkLoader: NSObject, DataLoading, @unchecked Sendable {
    // MARK: Private Properties
    private var activeTask: URLSessionDataTask?

    func request(_ endpoint: Endpoint, completion: @escaping (Result<DataResponse, Error>) -> Void) -> Progress {
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        
        guard let url = endpoint.url
        else {
            completion(.failure(NetworkError.badURL))
            return Progress(totalUnitCount: 1)
        }

        activeTask = urlSession.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(NetworkError.httpError(statusCode: httpResponse.statusCode)))
                return
            }

            if let data {
                let dataResponse = DataResponse(data: data, source: .network)
                completion(.success(dataResponse))
            } else {
                completion(.failure(NetworkError.emptyResponse))
            }
        }
        
        activeTask?.resume()
        urlSession.finishTasksAndInvalidate()

        return activeTask?.progress ?? Progress()
    }
    
    func cancel() {
        activeTask?.cancel()
    }
}

// MARK: - URLSessionDelegate
extension NetworkLoader: URLSessionDelegate { }
