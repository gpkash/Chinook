//
//  FetchAlertOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-12-20.
//

import Foundation

public class FetchAlertOperation: ConcurrentOperation<Alert>, @unchecked Sendable {
    // MARK: Private Properties
    private let dataLoader: DataLoader
    private let url: URL
    
    // MARK: - Lifecycle
    public init(url: URL, strategy: DataLoaderStrategy) {
        self.url = url
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
        
        let endpoint = Endpoint.alert(url: url)
        Task { @MainActor in
            let dataLoaderProgress = dataLoader.request(endpoint) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let dataResponse):
                    do {
                        if let responseString = String(data: dataResponse.data, encoding: .utf8) {
                            if responseString.contains("Barrie") {
                                print("\(self.url.absoluteString)")
                            }
                        }

                        let alert = try Alert.decode(fromXML: dataResponse.data)
                        self.complete(result: .success(alert))
                    }
                    catch {
                        self.complete(result: .failure(error))
                    }

                case .failure(let error):
                    self.complete(result: .failure(error))
                }
            }

            self.progress = dataLoaderProgress
        }
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
}
