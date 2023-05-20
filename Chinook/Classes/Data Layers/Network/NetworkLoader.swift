//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation


/// Handles network requests.
class NetworkLoader: NSObject {
    
    // MARK: Private Properties
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)    
}


// MARK: - DataLoading

extension NetworkLoader: DataLoading {
    func request(_ endpoint: Endpoint, completion: @escaping (Result<DataResponse, Error>) -> Void) -> Progress {
        guard let url = endpoint.url else {
            completion(.failure(NetworkError.badURL))
            return Progress(totalUnitCount: 1)
        }

        let task = urlSession.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data {
                let dataResponse = DataResponse(data: data, source: .network)
                completion(.success(dataResponse))
            }
        }

        task.resume()
        urlSession.finishTasksAndInvalidate()

        return task.progress
    }
    
    func cancel() {
        urlSession.invalidateAndCancel()
    }
}


// MARK: - URLSessionDelegate

extension NetworkLoader: URLSessionDelegate { }
