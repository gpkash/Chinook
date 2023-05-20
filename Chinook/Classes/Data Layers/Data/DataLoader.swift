//
//  DataLoader.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-22.
//

import Foundation


public enum DataLoaderStrategy {
    /// Only attempt loading an asset from the cache.
    case diskOnly
    /// Only attempt loading an asset from the network (will save to cache upon success).
    case networkOnly
    /// Try to the load the asset from disk and only hit the network if the asset is not on disk or a disk error occurred.
    case diskWithNetworkFallback
    /// Try to the load the asset from disk and then also load and the asset from the network.
    case diskThenNetwork
}


/// A repository that decides where to load data from (disk and/or network) and manages the disk caching.
public class DataLoader: NSObject {
    
    // MARK: Public Properties
    
    public let strategy: DataLoaderStrategy
    
    
    // MARK: Private Properties
    
    private let diskLoader = DiskLoader()
    private let networkLoader = NetworkLoader()
    private let queue = OperationQueue()
    
    
    // MARK: Property Overrides
    
    // MARK: - Lifecycle
    
    public init(strategy: DataLoaderStrategy = .diskWithNetworkFallback) {
        self.strategy = strategy
        
        super.init()        
    }
}

extension DataLoader: DataLoading {
    public func request(_ endpoint: Endpoint, completion: @escaping (Result<DataResponse, Error>) -> Void) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        
        switch strategy {
        case .diskOnly:
            let diskLoaderOperation = DiskLoaderOperation(endpoint: endpoint)
            diskLoaderOperation.completionHandler = { result in completion(result) }
            progress.addChild(diskLoaderOperation.progress, withPendingUnitCount: diskLoaderOperation.progress.totalUnitCount)
            
            queue.addOperation(diskLoaderOperation)
            
        case .networkOnly:
            let networkLoaderOperation = NetworkLoaderOperation(endpoint: endpoint)
            networkLoaderOperation.completionHandler = { [weak self] result in
                self?.cacheSuccessfulResult(result, onEndpoint: endpoint)
                completion(result)
            }
            progress.addChild(networkLoaderOperation.progress, withPendingUnitCount: networkLoaderOperation.progress.totalUnitCount)

            queue.addOperation(networkLoaderOperation)
        
        case .diskWithNetworkFallback:
            let diskLoaderOperation = DiskLoaderOperation(endpoint: endpoint)
            let networkLoaderOperation = NetworkLoaderOperation(endpoint: endpoint)

            diskLoaderOperation.completionHandler = { [weak self] result in
                switch result {
                case .success(_):
                    completion(result)
                    
                case .failure(let error):
                    // Don't forward `missingAsset` errors.
                    switch error {
                    case DiskLoaderError.missingAsset:
                        progress.addChild(networkLoaderOperation.progress, withPendingUnitCount: networkLoaderOperation.progress.totalUnitCount)

                        networkLoaderOperation.completionHandler = { [weak self] result in
                            self?.cacheSuccessfulResult(result, onEndpoint: endpoint)
                            completion(result)
                        }
                        
                        self?.queue.addOperation(networkLoaderOperation)
                        
                    default: completion(.failure(error))
                    }
                }
            }
            
            progress.addChild(diskLoaderOperation.progress, withPendingUnitCount: diskLoaderOperation.progress.totalUnitCount)
            
            queue.addOperation(diskLoaderOperation)
            
        case .diskThenNetwork:
            let diskLoaderOperation = DiskLoaderOperation(endpoint: endpoint)
            diskLoaderOperation.completionHandler = { result in
                switch result {
                case .success(_):
                    completion(result)
                    
                case .failure(let error):
                    // Don't forward `missingAsset` errors.
                    switch error {
                    case DiskLoaderError.missingAsset: break
                    default: completion(.failure(error))
                    }
                }
            }
            
            let networkLoaderOperation = NetworkLoaderOperation(endpoint: endpoint)
            networkLoaderOperation.completionHandler = { [weak self] result in
                self?.cacheSuccessfulResult(result, onEndpoint: endpoint)
                completion(result)
            }
            networkLoaderOperation.addDependency(diskLoaderOperation)
            
            progress.addChild(diskLoaderOperation.progress, withPendingUnitCount: diskLoaderOperation.progress.totalUnitCount)
            progress.addChild(networkLoaderOperation.progress, withPendingUnitCount: networkLoaderOperation.progress.totalUnitCount)

            queue.addOperations([diskLoaderOperation, networkLoaderOperation], waitUntilFinished: false)
        }

        return progress
    }
    
    public func cancel() {
        diskLoader.cancel()
        networkLoader.cancel()
    }
    
    
    // MARK: - Private Functions

}

private extension DataLoader {
    func cacheSuccessfulResult(_ result: Result<DataResponse, Error>, onEndpoint endpoint: Endpoint) {
        // Only check for success to perform cache.
        switch result {
        case .success(let dataResponse):
            endpoint.cache(dataResponse.data)
        default:
            break
        }
    }
}
