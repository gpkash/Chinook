//
//  FetchObservationCollectionOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-03-21.
//

import Foundation
import XMLCoder

public class FetchObservationCollectionOperation: ConcurrentOperation<ObservationCollection>, @unchecked Sendable {
    
    // MARK: Public Properties
    
    // MARK: Private Properties
    
    private let dataLoader: DataLoader
    private let provinceCode: String

    
    // MARK: Property Overrides

    // MARK: - Lifecycle
    
    public init(provinceCode: String, strategy: DataLoaderStrategy) {
        self.provinceCode = provinceCode
        self.dataLoader = DataLoader(strategy: strategy)
        super.init()
    }

    
    // MARK: - Function Overrides
    
    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        let endpoint = Endpoint.observationCollection(forProvinceWithCode: provinceCode)

        Task { @MainActor in
            let dataLoaderProgress = dataLoader.request(endpoint) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let dataResponse):
                    do {
                        let observationCollection = try ObservationCollection.decode(
                            fromXML: dataResponse.data,
                            keyDecodingStrategy: .observationCollectionCustomStrategy
                        )
                        self.complete(result: .success(observationCollection))
                    } catch {
                        self.complete(result: .failure(error))
                    }

                case .failure(let error):
                    self.complete(result: .failure(error))
                }
            }

            self.progress.addChild(dataLoaderProgress, withPendingUnitCount: 1)
        }
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
}
