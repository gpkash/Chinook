//
//  FetchCityPageWeatherSiteListOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public class FetchCityPageWeatherSiteListOperation: ConcurrentOperation<SiteList>, @unchecked Sendable {
    // MARK: Private Properties
    private let dataLoader: DataLoader
    
    // MARK: - Lifecycle
    public init(strategy: DataLoaderStrategy) {
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

        Task { @MainActor in
            let endpoint = Endpoint.citypageWeatherSiteList

            let dataLoaderProgress = dataLoader.request(endpoint) { [weak self] result in
                guard let self else { return }

                switch result {
                case .success(let dataResponse):
                    do {
                        let siteList = try SiteList.decode(fromXML: dataResponse.data)
                        self.complete(result: .success(siteList))
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
