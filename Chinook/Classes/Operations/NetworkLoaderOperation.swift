//
//  NetworkLoaderOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-01.
//

import Foundation

public class NetworkLoaderOperation: ConcurrentOperation<DataResponse> {
    
    // MARK: Public Properties
    
    // MARK: Private Properties
    
    private let endpoint: Endpoint
    private let networkLoader = NetworkLoader()

    
    // MARK: Property Overrides

    // MARK: - Lifecycle
    
    public init(endpoint: Endpoint) {
        self.endpoint = endpoint
        super.init()
    }

    
    // MARK: - Function Overrides
    
    // MARK: - Public Functions
    
    // MARK: - Private Functions

    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        let networkLoaderProgress = networkLoader.request(endpoint) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dataResponse):
                    self?.complete(result: .success(dataResponse))
                    
                case .failure(let error):
                    self?.complete(result: .failure(error))
                }
            }
        }
        
        progress.addChild(networkLoaderProgress, withPendingUnitCount: 1)
    }
    
    override public func cancel() {
        networkLoader.cancel()
        super.cancel()
    }
}
