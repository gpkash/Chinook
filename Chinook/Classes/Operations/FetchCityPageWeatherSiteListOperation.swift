//
//  FetchCityPageWeatherSiteListOperation.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-09.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import Foundation

public class FetchCityPageWeatherSiteListOperation: ConcurrentOperation {
    
    private let dataLoader = DataLoader()
    
    override public func start() {
        super.start()
        
        dataLoader.request(.citypageWeatherSiteList) { [weak self] result in
            switch result {
            case .success(let data):
                do {
                    let siteList = try SiteList.decode(fromXML: data)
                    self?.complete(result: .success(siteList))
                }
                catch {
                    self?.complete(result: .failure(error))
                }

            case .failure(let error):
                self?.complete(result: .failure(error))
            }
        }
    }
    
    override public func cancel() {
        dataLoader.cancel()
        super.cancel()
    }
}
