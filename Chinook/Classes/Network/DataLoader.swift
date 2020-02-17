//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

class DataLoader: NSObject {
    
    // MARK: Private
    
    private lazy var urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    
    // MARK: Public Functions

    func request(_ endpoint: Endpoint, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = endpoint.url else {
            return completion(.failure(NetworkError.badURL))
        }

        let task = urlSession.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data {
                completion(.success(data))
            }
        }

        task.resume()
    }
        
    func cancel() {
        urlSession.invalidateAndCancel()
    }
}

extension DataLoader: URLSessionDelegate {

}
