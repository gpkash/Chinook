//
//  FetchCityPageWeatherSiteDataOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

class FetchCityPageWeatherSiteDataOperation: ConcurrentOperation {
    
    private let dataLoader = DataLoader()
    private let site: Site
    
    init(site: Site) {
        self.site = site
    }
    
    override func start() {
        super.start()
        
        let endpoint = Endpoint.cityPageWeather(forSite: site)
        
        dataLoader.request(endpoint) { [weak self] result in
            switch result {
            case .success(let data):
                do {
                    let siteData = try SiteData.decode(fromXML: data)
                    self?.complete(result: .success(siteData))
                }
                catch {
                    self?.complete(result: .failure(error))
                }
                
            case .failure(let error):
                self?.complete(result: .failure(error))
            }
        }
    }
    
    override func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
}
