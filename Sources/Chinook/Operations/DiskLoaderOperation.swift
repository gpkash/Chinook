//
//  DiskLoaderOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-01.
//

import Foundation

@MainActor
public class DiskLoaderOperation: ConcurrentOperation<DataResponse>, @unchecked Sendable {

    // MARK: Private Properties
    private let endpoint: Endpoint
    private let diskLoader = DiskLoader()

    // MARK: - Lifecycle
    public init(endpoint: Endpoint) {
        self.endpoint = endpoint
        super.init()
    }

    // MARK: - Function Overrides
    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        Task { @MainActor in
            let diskLoaderProgress = diskLoader.request(endpoint) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let dataResponse):
                    self.complete(result: .success(dataResponse))

                case .failure(let error):
                    self.complete(result: .failure(error))
                }
            }

            self.progress.addChild(diskLoaderProgress, withPendingUnitCount: 1)
        }
    }
    
    override public func cancel() {
        Task { @MainActor in
            self.diskLoader.cancel()
        }
        super.cancel()
    }
}
