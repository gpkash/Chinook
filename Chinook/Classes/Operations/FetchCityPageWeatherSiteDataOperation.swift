//
//  FetchCityPageWeatherSiteDataOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public class FetchCityPageWeatherSiteDataOperation: ConcurrentOperation<SiteData> {
    
    // MARK: Public Properties
    
    // MARK: Private Properties
    
    private let dataLoader: DataLoader
    private let site: Site

    
    // MARK: Property Overrides

    // MARK: - Lifecycle
    
    public init(site: Site, strategy: DataLoaderStrategy) {
        self.site = site
        self.dataLoader = DataLoader(strategy: strategy)
        super.init()
    }


    // MARK: - Private Functions

    override public func start() {
        super.start()
        
        guard !isCancelled else {
            finish()
            return
        }
        
        let endpoint = Endpoint.cityPageWeather(forSite: site)
        
        let dataLoaderProgress = dataLoader.request(endpoint) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dataResponse):
                    do {
                        let siteData = try SiteData.decode(fromXML: dataResponse.data)
                        DispatchQueue.main.async {
                            self?.complete(result: .success(siteData))
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
        }
        
        progress.addChild(dataLoaderProgress, withPendingUnitCount: 1)
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
}
