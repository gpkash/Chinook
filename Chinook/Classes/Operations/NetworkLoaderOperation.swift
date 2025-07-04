//
//  NetworkLoaderOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-01.
//

import Foundation

@MainActor
public class NetworkLoaderOperation: ConcurrentOperation<DataResponse> {
    // MARK: Private Properties
    private let endpoint: Endpoint
    private let networkLoader = NetworkLoader()

    // MARK: - Lifecycle
    public init(endpoint: Endpoint) {
        self.endpoint = endpoint
        super.init()
    }

    // MARK: - Private Functions
    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        let networkLoaderProgress = networkLoader.request(endpoint) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let dataResponse):
                self.complete(result: .success(dataResponse))

            case .failure(let error):
                self.complete(result: .failure(error))
            }
        }
        
        progress.addChild(networkLoaderProgress, withPendingUnitCount: 1)
    }
    
    override public func cancel() {
        networkLoader.cancel()
        super.cancel()
    }
}
