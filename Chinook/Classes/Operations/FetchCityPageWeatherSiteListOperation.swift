//
//  FetchCityPageWeatherSiteListOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public class FetchCityPageWeatherSiteListOperation: ConcurrentOperation<SiteList> {
    
    // MARK: Public Properties
    
    // MARK: Private Properties
    
    private let dataLoader: DataLoader
    
    
    // MARK: Property Overrides

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
        
        let dataLoaderProgress = dataLoader.request(.citypageWeatherSiteList) { [weak self] result in
            switch result {
            case .success(let dataResponse):
                do {
                    let siteList = try SiteList.decode(fromXML: dataResponse.data)
                    DispatchQueue.main.async {
                        self?.complete(result: .success(siteList))
                    }
                }
                catch {
                    DispatchQueue.main.async {
                        self?.complete(result: .failure(error))
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.complete(result: .failure(error))
                }
            }
        }
        
        progress.addChild(dataLoaderProgress, withPendingUnitCount: 1)
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
    
    // MARK: - Public Functions
    
    // MARK: - Private Functions
}
