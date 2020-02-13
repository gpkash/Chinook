//
//  ViewController.swift
//  Chinook
//
//  Created by Gary Kash on 2020-02-01.
//  Copyright © 2020 Gary Kash. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let queue = OperationQueue()
    
    lazy var citySiteDataOperationCompletionHandler: (_ result: Result<Any, Error>) -> Void = { [weak self] result in
        switch result {
        case .success(let siteData):
            let siteData = siteData as! SiteData
            if let temperature = siteData.currentConditions?.temperature.value {
                print("\(temperature)C in \(siteData.location.name.value)")
            }
            else {
                print("temperature unavailable in \(siteData.location.name.value)")
            }
            
        case .failure(let error):
            self?.showAlert(forError: error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let fetchCityPageWeatherSiteListOperation = FetchCityPageWeatherSiteListOperation()
        
        fetchCityPageWeatherSiteListOperation.completionHandler = { [weak self] result in
            switch result {
            case .success(let siteList):
                let siteList = siteList as! SiteList
                print("\(siteList.site.count) sites fetched.")
                
                self?.loadSiteData(siteList)
                
            case .failure(let error):
                self?.showAlert(forError: error)
            }
        }
        
        queue.maxConcurrentOperationCount = 10
        queue.addOperation(fetchCityPageWeatherSiteListOperation)
    }
    
    private func loadSiteData(_ siteList: SiteList) {
        siteList.site.forEach { site in
            let fetchCityPageWeatherSiteDataOperation = FetchCityPageWeatherSiteDataOperation(site: site)
            fetchCityPageWeatherSiteDataOperation.completionHandler = citySiteDataOperationCompletionHandler
            queue.addOperation(fetchCityPageWeatherSiteDataOperation)
        }
    }
}

